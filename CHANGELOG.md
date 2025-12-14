# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-12-14
- Simplifies and updates cluster configuration

Streamlines cluster configuration by removing unnecessary settings and updating defaults.

- Removes unused configurations for a cleaner setup.
- Corrects autoscaler expander option for proper autoscaling behavior.
- Sets a default batch node pool size to ensure resources are available.
- Makes kubeconfig host output sensitive to prevent accidental exposure.
- Enforces node pool size and min_size to be at least 1 to avoid configuration issues.
- Refactors module for enhanced Kubernetes deployment

Improves the Scaleway Kubernetes Terraform module with comprehensive configuration options and enhanced features for Kapsule cluster management.

The changes include:
- Introduces a new README with detailed documentation and usage examples.
- Restructures the example configurations for clarity.
- Enhances variable definitions with validations and descriptions.
- Simplifies resource configurations for better management.
- Adds output configurations for Terraform providers.
- Refactors module for improved Scaleway K8s management

Migrates the Terraform module to use more explicit and descriptive variables, data sources, and resource configurations for managing Scaleway Kubernetes clusters (Kapsule).

This change streamlines cluster creation, configuration, and node pool management, enhancing the module's usability and flexibility. It introduces comprehensive examples, clear output definitions, and validations.
- generalize container runtime map variable
- run pre commit
- create scw kapsule module
- Initial commit

