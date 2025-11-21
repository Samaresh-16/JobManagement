package com.bits.scalable.notificationservice.service;

import com.bits.scalable.notificationservice.model.Notification;
import com.bits.scalable.notificationservice.repository.NotificationRepository;
import com.bits.scalable.notificationservice.request.SendNotificationRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {
    private final NotificationRepository notificationRepository;

    public void save(SendNotificationRequest request) {
        var notification = Notification.builder()
                .id(UUID.randomUUID().toString())
                .userId(request.getUserId())
                .offerId(request.getOfferId())
                .message(request.getMessage())
                .build();
        notificationRepository.save(notification);
    }

    public List<Notification> getAllByUserId(String id) {
        return notificationRepository.findAllByUserIdOrderByCreationTimestampDesc(id);
    }
}
