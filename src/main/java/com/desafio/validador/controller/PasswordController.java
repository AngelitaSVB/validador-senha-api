package com.desafio.validador.controller;

import com.desafio.validador.model.PasswordRequest;
import com.desafio.validador.model.PasswordResponse;
import com.desafio.validador.service.PasswordService;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Map;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@RestController
@RequestMapping("/api")
@CrossOrigin(origins = {
        "http://localhost:4200",
        "http://validador-dev-placeholder.s3-website-sa-east-1.amazonaws.com",
        "https://validador-dev-placeholder.s3-website-sa-east-1.amazonaws.com",
        "https://zf8uy62f71.execute-api.sa-east-1.amazonaws.com"
})
public class PasswordController {

    private final PasswordService passwordService;

    @Value("${JWT_SECRET}")
    private String jwtSecret;

    private SecretKey secretKey;

    public PasswordController(PasswordService passwordService) {
        this.passwordService = passwordService;
    }

    @PostConstruct
    public void initSecretKey() {
        this.secretKey = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
    }

    @PostMapping("/validar")
    public ResponseEntity<?> validarSenha(
            @RequestHeader(HttpHeaders.AUTHORIZATION) String authorization,
            @RequestBody(required = false) PasswordRequest request) {
        try {
            if (authorization == null || !authorization.startsWith("Bearer ")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("erro", "Token ausente ou inválido"));
            }

            String token = authorization.substring(7);
            Jwts.parserBuilder().setSigningKey(secretKey).build().parseClaimsJws(token);

            // 🚨 Verificação extra: corpo da requisição nulo ou senha ausente
            if (request == null || request.getSenha() == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of("erro", "Campo 'senha' está ausente ou nulo."));
            }

            // ✅ Validação da senha via serviço
            PasswordResponse response = passwordService.validarSenha(request.getSenha());
            return ResponseEntity.ok(response);

        } catch (JwtException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("erro", "Token inválido ou expirado"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("erro", "Erro interno: " + e.getMessage()));
        }
    }
}
