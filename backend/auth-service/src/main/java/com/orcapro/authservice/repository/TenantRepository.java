package com.orcapro.authservice.repository;

import com.orcapro.authservice.entity.Tenant;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TenantRepository extends JpaRepository<Tenant, Long> {
    boolean existsByName(String name);
    boolean existsBySchema(String schema);
}