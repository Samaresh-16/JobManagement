package com.bits.scalable.authservice.dto;

import com.bits.scalable.authservice.enums.Role;
import lombok.Data;

@Data
public class UserDto {
    private String id;
    private String username;
    private String password;
    private Role role;
}
