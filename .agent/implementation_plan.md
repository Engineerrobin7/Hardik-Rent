# HardikRent Implementation Plan
Based on "Rent Collection App" Specification

## Phase 1: Foundation & Data Structures (Current Focus)
- [x] Create Basic MVP (Done)
- [ ] **Refactor Data Models**:
    - [ ] `Property`: Add configuration for penalties, grace period, due date.
    - [ ] `Tenant`: Add emergency contact, deposit, doc URLs.
    - [ ] `RentRecord`: Add breakdown for rent, electricity, penalty, and status flags (Green/Yellow/Red).
- [ ] **Business Logic Core (AppProvider)**:
    - [ ] Implement Flag Logic (Yellow vs Red vs Green).
    - [ ] Implement Penalty Calculation (Daily vs Flat).
    - [ ] Implement Mock Data scenarios for all flags.

## Phase 2: Core Modules
- [ ] **Tenant Onboarding**:
    - [ ] Update `AddTenantScreen` with new fields (ID, Agreement).
    - [ ] Add Document Upload UI (Placeholder for now).
- [ ] **Rent Cycle & Payment**:
    - [ ] Automate Rent Generation Check.
    - [ ] `PaymentSubmission` with detailed breakdown.
- [ ] **Electricity Module**:
    - [ ] New Screen: `ElectricityMeterScreen`.
    - [ ] Link reading to Rent Record.

## Phase 3: Dashboard & Analytics
- [ ] **Owner Dashboard**:
    - [ ] Update stats to show Green/Yellow/Red breakdown.
    - [ ] Add Defaulter list.
- [ ] **Notices**:
    - [ ] Generate PDF templates.

## Phase 4: Backend Integration
- [ ] Setup Firebase Project.
- [ ] Migrate Mock Data to Firestore.
- [ ] Implement Storage for Docs.
