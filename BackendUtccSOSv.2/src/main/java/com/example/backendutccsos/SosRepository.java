package com.example.backendutccsos;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SosRepository extends JpaRepository<SosReq, Long> {
    //Ascending order newest to oldest
    List<SosReq> findByUserIdOrderByCreatedAtDesc(String userId);
    // For Admin
    List<SosReq> findAllByOrderByCreatedAtDesc();
}
