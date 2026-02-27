#!/bin/bash
# ============================================================================
# ENTERPRISE HEALTHCARE DATA PLATFORM - DEPLOYMENT ORCHESTRATOR
# ============================================================================
# File: deploy.sh
# Purpose: CI/CD deployment orchestration script
# Version: 2.0.0
# Usage: ./deploy.sh --env DEV|QA|PROD [--phase N] [--dry-run]
# ============================================================================

set -e  # Exit on error
set -o pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEPLOYMENT_ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)

# Default values
ENV="DEV"
PHASE=""
DRY_RUN=false
SKIP_VALIDATION=false

# Snowflake connection (from environment or CI/CD secrets)
SNOWFLAKE_ACCOUNT="${SNOWFLAKE_ACCOUNT:-}"
SNOWFLAKE_USER="${SNOWFLAKE_USER:-}"
SNOWFLAKE_ROLE="${SNOWFLAKE_ROLE:-ACCOUNTADMIN}"
SNOWFLAKE_WAREHOUSE="${SNOWFLAKE_WAREHOUSE:-COMPUTE_WH}"

# Git info (from CI/CD)
GIT_COMMIT="${GIT_COMMIT:-$(git rev-parse --short HEAD 2>/dev/null || echo 'LOCAL')}"
GIT_BRANCH="${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')}"

# ============================================================================
# DEPLOYMENT SEQUENCE (Dependency Order)
# ============================================================================

declare -a DEPLOY_SEQUENCE=(
    "01_deployment_logger.sql:0:Deployment Logger"
    "02_security_foundation.sql:1:Security Foundation"
    "03_rbac_hierarchy.sql:2:RBAC Hierarchy"
    "04_compute_infrastructure.sql:3:Compute Infrastructure"
    "05_data_architecture.sql:4:Data Architecture"
    "06_medallion_tables.sql:5:Medallion Tables"
    "07_governance_policies.sql:6:Governance Policies"
    "08_monitoring_alerts.sql:7:Monitoring & Alerts"
    "09_audit_compliance.sql:8:Audit & Compliance"
    "10_ai_ready_layer.sql:9:AI-Ready Layer"
    "11_data_quality.sql:10:Data Quality Framework"
    "12_validation_tests.sql:11:Validation Tests"
)

# ============================================================================
# FUNCTIONS
# ============================================================================

usage() {
    cat << EOF
Healthcare Enterprise Data Platform - Deployment Script

Usage: $0 [OPTIONS]

Options:
    --env ENV           Target environment (DEV|QA|PROD) [default: DEV]
    --phase N           Deploy only phase N (0-11)
    --dry-run           Validate scripts without executing
    --skip-validation   Skip post-deployment validation
    --rollback PHASE    Rollback specific phase
    -h, --help          Show this help message

Environment Variables:
    SNOWFLAKE_ACCOUNT   Snowflake account identifier
    SNOWFLAKE_USER      Snowflake username
    SNOWFLAKE_PASSWORD  Snowflake password (or use key-pair auth)
    SNOWFLAKE_ROLE      Snowflake role [default: ACCOUNTADMIN]

Examples:
    # Deploy to DEV
    ./deploy.sh --env DEV

    # Deploy specific phase to QA
    ./deploy.sh --env QA --phase 5

    # Dry run for PROD
    ./deploy.sh --env PROD --dry-run

    # Deploy via CI/CD
    SNOWFLAKE_ACCOUNT=xxx SNOWFLAKE_USER=yyy ./deploy.sh --env PROD

EOF
    exit 0
}

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_DIR}/deploy_${TIMESTAMP}.log"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

validate_environment() {
    if [[ ! "$ENV" =~ ^(DEV|QA|PROD)$ ]]; then
        log_error "Invalid environment: $ENV. Must be DEV, QA, or PROD"
        exit 1
    }

    if [[ "$ENV" == "PROD" && -z "$SNOWFLAKE_ACCOUNT" ]]; then
        log_error "PROD deployment requires SNOWFLAKE_ACCOUNT to be set"
        exit 1
    }

    # PROD deployment safeguards
    if [[ "$ENV" == "PROD" ]]; then
        log_warn "⚠️  PRODUCTION DEPLOYMENT DETECTED"
        if [[ -z "$CI" ]]; then
            read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm
            if [[ "$confirm" != "yes" ]]; then
                log_info "Deployment cancelled"
                exit 0
            fi
        fi
    fi
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check snowsql
    if ! command -v snowsql &> /dev/null; then
        log_error "snowsql not found. Install Snowflake CLI first."
        exit 1
    fi

    # Check connection
    if [[ -n "$SNOWFLAKE_ACCOUNT" ]]; then
        log_info "Testing Snowflake connection..."
        if ! snowsql -q "SELECT CURRENT_TIMESTAMP()" &> /dev/null; then
            log_error "Failed to connect to Snowflake"
            exit 1
        fi
        log_success "Snowflake connection verified"
    fi
}

execute_script() {
    local script=$1
    local phase=$2
    local description=$3
    local script_path="${SCRIPT_DIR}/deploy/${script}"

    if [[ ! -f "$script_path" ]]; then
        log_warn "Script not found: $script_path (skipping)"
        return 0
    fi

    log_info "Executing Phase $phase: $description"
    log_info "Script: $script"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would execute: $script_path"
        # Validate syntax only
        snowsql -f "$script_path" \
            -D ENV="$ENV" \
            -D GIT_COMMIT="$GIT_COMMIT" \
            -D GIT_BRANCH="$GIT_BRANCH" \
            -D DEPLOYMENT_ID="$DEPLOYMENT_ID" \
            --syntax-only 2>&1 | tee -a "${LOG_DIR}/deploy_${TIMESTAMP}.log"
        return 0
    fi

    # Execute script
    local start_time=$(date +%s)
    
    if snowsql -f "$script_path" \
        -D ENV="$ENV" \
        -D GIT_COMMIT="$GIT_COMMIT" \
        -D GIT_BRANCH="$GIT_BRANCH" \
        -D DEPLOYMENT_ID="$DEPLOYMENT_ID" \
        -o exit_on_error=true \
        -o timing=true \
        2>&1 | tee -a "${LOG_DIR}/deploy_${TIMESTAMP}.log"; then
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Phase $phase completed in ${duration}s"
        return 0
    else
        log_error "Phase $phase FAILED"
        return 1
    fi
}

deploy_all() {
    log_info "Starting full deployment to $ENV"
    log_info "Deployment ID: $DEPLOYMENT_ID"
    log_info "Git Commit: $GIT_COMMIT"
    log_info "Git Branch: $GIT_BRANCH"

    local failed=0

    for entry in "${DEPLOY_SEQUENCE[@]}"; do
        IFS=':' read -r script phase description <<< "$entry"
        
        # Skip if specific phase requested
        if [[ -n "$PHASE" && "$phase" != "$PHASE" ]]; then
            continue
        fi

        if ! execute_script "$script" "$phase" "$description"; then
            failed=$((failed + 1))
            log_error "Deployment failed at Phase $phase"
            
            # In PROD, stop on first failure
            if [[ "$ENV" == "PROD" ]]; then
                log_error "PROD deployment halted due to failure"
                exit 1
            fi
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_error "Deployment completed with $failed failures"
        exit 1
    else
        log_success "Deployment completed successfully"
    fi
}

rollback() {
    local phase=$1
    local rollback_script="${SCRIPT_DIR}/rollback/$(printf '%02d' $phase)_rollback.sql"

    if [[ ! -f "$rollback_script" ]]; then
        log_error "Rollback script not found: $rollback_script"
        exit 1
    fi

    log_warn "Rolling back Phase $phase..."
    
    if snowsql -f "$rollback_script" \
        -D ENV="$ENV" \
        -o exit_on_error=true \
        2>&1 | tee -a "${LOG_DIR}/rollback_${TIMESTAMP}.log"; then
        log_success "Rollback completed"
    else
        log_error "Rollback failed"
        exit 1
    fi
}

generate_report() {
    log_info "Generating deployment report..."

    cat << EOF > "${LOG_DIR}/report_${TIMESTAMP}.md"
# Deployment Report

## Summary
- **Environment:** $ENV
- **Deployment ID:** $DEPLOYMENT_ID
- **Git Commit:** $GIT_COMMIT
- **Git Branch:** $GIT_BRANCH
- **Timestamp:** $(date)
- **Status:** COMPLETED

## Phases Deployed
$(for entry in "${DEPLOY_SEQUENCE[@]}"; do
    IFS=':' read -r script phase description <<< "$entry"
    echo "- Phase $phase: $description"
done)

## Log File
${LOG_DIR}/deploy_${TIMESTAMP}.log

EOF

    log_info "Report generated: ${LOG_DIR}/report_${TIMESTAMP}.md"
}

# ============================================================================
# MAIN
# ============================================================================

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENV="$2"
            shift 2
            ;;
        --phase)
            PHASE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        --rollback)
            rollback "$2"
            exit 0
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Create log directory
mkdir -p "$LOG_DIR"

# Run deployment
log_info "============================================"
log_info "Healthcare Enterprise Data Platform"
log_info "Deployment Orchestrator v2.0.0"
log_info "============================================"

validate_environment
check_prerequisites
deploy_all
generate_report

log_success "============================================"
log_success "Deployment Complete!"
log_success "============================================"
