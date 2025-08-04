## 1.4.0-dev - Architectural Changes and Major Refactoring:

This release marks a significant architectural overhaul across the Open Neom ecosystem, with `neom_core` playing a central role in defining the new, more robust, and maintainable structure. The primary focus has been on enhancing decoupling, testability, and clarity of responsibilities.

**Key Architectural Improvements:**

* **Enhanced Dependency Inversion (DIP) & Testability:**
    * Introduced and/or refactored **service interfaces (use_cases)** for most core controllers. This promotes loose coupling and significantly improves the testability of business logic.
    * Concrete implementations now explicitly implement their respective interfaces, ensuring adherence to contracts.

* **Consolidation and Clear Responsibilities:**
* **Improved Constants and Enums Management:**