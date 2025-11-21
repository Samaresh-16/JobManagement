package com.bits.scalable.filestorage.repository;

import com.bits.scalable.filestorage.model.File;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FileRepository extends JpaRepository<File, String> {
}
