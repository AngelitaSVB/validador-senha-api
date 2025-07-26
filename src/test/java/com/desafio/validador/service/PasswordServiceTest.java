package com.desafio.validador.service;

import com.desafio.validador.model.PasswordResponse;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;
class PasswordServiceTest {

    private final PasswordService service = new PasswordService();

    @Test
    public void senhaValida_DeveRetornarValidoTrue() {
        String senha = "AbTp9!fok";
        PasswordResponse response = service.validarSenha(senha);

        assertTrue(response.isValido());
        assertTrue(response.getMotivos().isEmpty());
    }

    @Test
    public void senhaCurta_DeveRetornarErro() {
        String senha = "Ab1!";
        PasswordResponse response = service.validarSenha(senha);

        assertFalse(response.isValido());
        assertTrue(response.getMotivos().contains("A senha deve conter no mínimo 9 caracteres."));
    }

    @Test
    public void senhaSemCaracterEspecial_DeveRetornarErro() {
        String senha = "AbTp9fokm";
        PasswordResponse response = service.validarSenha(senha);

        assertFalse(response.isValido());
        assertTrue(response.getMotivos().stream().anyMatch(m -> m.contains("caractere especial")));
    }

    @Test
    public void senhaComCaracteresRepetidos_DeveRetornarErro() {
        String senha = "AbTp9!foo";
        PasswordResponse response = service.validarSenha(senha);

        assertFalse(response.isValido());
        assertTrue(response.getMotivos().stream().anyMatch(m -> m.contains("repetidos")));
    }

    @Test
    public void senhaSemMaiuscula_DeveRetornarErro() {
        String senha = "abtp9!fok";
        PasswordResponse response = service.validarSenha(senha);

        assertFalse(response.isValido());
        assertTrue(response.getMotivos().stream().anyMatch(m -> m.contains("letra maiúscula")));
    }

    @Test
    public void senhaComEspaco_DeveRetornarErro() {
        String senha = "AbTp9! fok";
        PasswordResponse response = service.validarSenha(senha);

        assertFalse(response.isValido());
        assertTrue(response.getMotivos().stream().anyMatch(m -> m.contains("Espaços")));
    }
}