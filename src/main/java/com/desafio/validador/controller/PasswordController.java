
package com.desafio.validador.controller;

import com.desafio.validador.model.PasswordRequest;
import com.desafio.validador.model.PasswordResponse;
import com.desafio.validador.service.PasswordService;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

@CrossOrigin(origins = {
        "http://localhost:4200",
        "https://validador-dev-placeholder.s3-website-sa-east-1.amazonaws.com",
        "https://87eua3p1ff.execute-api.sa-east-1.amazonaws.com/dev"
})
@RestController
@RequestMapping("/api")
public class PasswordController {

    @Autowired
    private PasswordService passwordService;

    private static final SecretKey secretKey = Keys.hmacShaKeyFor("itau-secret-itau-secret-itau-secret".getBytes(StandardCharsets.UTF_8));

    @PostMapping("/validar")
    public ResponseEntity<?> validarSenha(@RequestHeader(HttpHeaders.AUTHORIZATION) String authorization,
                                          @RequestBody PasswordRequest request) {
        try {
            if (authorization == null || !authorization.startsWith("Bearer ")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Token ausente ou inválido");
            }

            String token = authorization.substring(7);
            Jws<Claims> claims = Jwts.parserBuilder()
                    .setSigningKey(secretKey)
                    .build()
                    .parseClaimsJws(token);

            PasswordResponse response = passwordService.validarSenha(request.getSenha());
            return ResponseEntity.ok(response);

        } catch (JwtException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Token inválido ou expirado");
        }
    }
}
