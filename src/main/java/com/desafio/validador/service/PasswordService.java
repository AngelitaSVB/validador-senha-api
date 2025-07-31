package com.desafio.validador.service;

import com.desafio.validador.model.PasswordResponse;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class PasswordService {

    public PasswordResponse validarSenha(String senha) {
        List<String> motivos = new ArrayList<>();

        // ✅ Validação nula antecipada
        if (senha == null) {
            motivos.add("A senha não pode ser nula.");
            return new PasswordResponse(false, motivos);
        }

        if (senha.contains(" ")) {
            motivos.add("Espaços em branco não são válidos.");
            return new PasswordResponse(false, motivos);
        }

        if (senha.length() < 9)
            motivos.add("A senha deve conter no mínimo 9 caracteres.");

        if (!senha.matches(".*\\d.*"))
            motivos.add("A senha deve conter ao menos um dígito.");

        if (!senha.matches(".*[a-z].*"))
            motivos.add("A senha deve conter ao menos uma letra minúscula.");

        if (!senha.matches(".*[A-Z].*"))
            motivos.add("A senha deve conter ao menos uma letra maiúscula.");

        if (!senha.matches(".*[!@#$%^&*()\\-+].*"))
            motivos.add("A senha deve conter ao menos um caractere especial (!@#$%^&*()-+).");

        Set<Character> caracteres = new HashSet<>();
        for (char c : senha.toCharArray()) {
            if (!caracteres.add(c)) {
                motivos.add("A senha não deve conter caracteres repetidos.");
                break; // pode ser return, mas aqui é um aviso leve
            }
        }

        boolean valido = motivos.isEmpty();
        return new PasswordResponse(valido, motivos);
    }
}
