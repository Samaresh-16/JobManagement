package com.bits.scalable.jobservice.repository;

import com.bits.scalable.jobservice.enums.Advertiser;
import com.bits.scalable.jobservice.model.Advert;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AdvertRepository extends JpaRepository<Advert, String> {
    List<Advert> getAdvertsByUserIdAndAdvertiser(String id, Advertiser advertiser);
}
