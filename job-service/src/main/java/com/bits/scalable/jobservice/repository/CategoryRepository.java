package com.bits.scalable.jobservice.repository;

import com.bits.scalable.jobservice.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, String> {
}
