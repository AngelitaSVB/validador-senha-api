package com.desafio.validador.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Base64;
import java.util.Map;

@RestController
@RequestMapping("/oauth")
@CrossOrigin(origins = "http://localhost:4200")
public class AuthController {

    @Value("${CLIENT_ID}")
    private String clientId;

    @Value("${CLIENT_SECRET}")
    private String clientSecret;

    @PostMapping("/token")
    public ResponseEntity<?> gerarToken(@RequestParam String grant_type,
            @RequestParam String client_id,
            @RequestParam String client_secret) {

        if ("client_credentials".equals(grant_type)
                && client_id.equals(clientId)
                && client_secret.equals(clientSecret)) {

            String fakeToken = Base64.getEncoder().encodeToString("frontend-itau-token".getBytes());

            return ResponseEntity.ok(Map.of(
                    "access_token", fakeToken,
                    "token_type", "Bearer",
                    "expires_in", "3600"));
        } else {
            return ResponseEntity.status(401).body("Credenciais inválidas");
        }
    }
}
