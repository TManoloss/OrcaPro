package com.orcapro.authservice.service;

import com.orcapro.authservice.dto.LoginRequest;
import com.orcapro.authservice.dto.LoginResponse;
import com.orcapro.authservice.dto.SignupRequest;
import com.orcapro.authservice.entity.Tenant;
import com.orcapro.authservice.entity.User;
import com.orcapro.authservice.entity.Role;
import com.orcapro.authservice.repository.TenantRepository;
import com.orcapro.authservice.repository.UserRepository;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    
    private final TenantRepository tenantRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    
    public AuthService(TenantRepository tenantRepository,
                      UserRepository userRepository,
                      PasswordEncoder passwordEncoder,
                      JwtService jwtService,
                      AuthenticationManager authenticationManager) {
        this.tenantRepository = tenantRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
    }
    
    @Transactional
    public void signup(SignupRequest signupRequest) {
        // Create tenant
        Tenant tenant = new Tenant();
        tenant.setName(signupRequest.getTenantName());
        tenant.setSchema(signupRequest.getTenantName().toLowerCase());
        tenantRepository.save(tenant);
        
        // Create admin user
        User user = new User();
        user.setEmail(signupRequest.getEmail());
        user.setPassword(passwordEncoder.encode(signupRequest.getPassword()));
        user.setTenant(tenant);
        user.setRole(Role.ADMIN);
        userRepository.save(user);
    }
    
    public LoginResponse login(LoginRequest loginRequest) {
        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(
                loginRequest.getEmail(), 
                loginRequest.getPassword()));
        
        SecurityContextHolder.getContext().setAuthentication(authentication);
        
        User user = (User) authentication.getPrincipal();
        String jwtToken = jwtService.generateToken(user);
        
        return new LoginResponse(jwtToken);
    }
}