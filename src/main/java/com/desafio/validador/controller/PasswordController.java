
package com.desafio.validador.controller;

import com.desafio.validador.model.PasswordRequest;
import com.desafio.validador.model.PasswordResponse;
import com.desafio.validador.service.PasswordService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "http://localhost:4200")
@RestController
@RequestMapping("/api")
public class PasswordController {

    @Autowired
    private PasswordService passwordService;

    @PostMapping("/validar")
    public PasswordResponse validarSenha(@RequestBody PasswordRequest request) {
        return passwordService.validarSenha(request.getSenha());
    }
}
