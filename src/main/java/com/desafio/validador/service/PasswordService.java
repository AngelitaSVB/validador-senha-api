
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

        if (senha == null || senha.length() < 9)
            motivos.add("A senha deve conter no mínimo 9 caracteres.");

        if (!senha.matches(".*\\d.*"))
            motivos.add("A senha deve conter ao menos um dígito.");

        if (!senha.matches(".*[a-z].*"))
            motivos.add("A senha deve conter ao menos uma letra minúscula.");

        if (!senha.matches(".*[A-Z].*"))
            motivos.add("A senha deve conter ao menos uma letra maiúscula.");

        if (!senha.matches(".*[!@#$%^&*()\\-+].*"))
            motivos.add("A senha deve conter ao menos um caractere especial (!@#$%^&*()-+).");

        if (senha != null) {
            Set<Character> caracteres = new HashSet<>();
            for (char c : senha.toCharArray()) {
                if (c == ' ') {
                    motivos.add("Espaços em branco não são válidos.");
                    break;
                }
                if (!caracteres.add(c)) {
                    motivos.add("A senha não deve conter caracteres repetidos.");
                    break;
                }
            }
        }

        boolean valido = motivos.isEmpty();
        return new PasswordResponse(valido, motivos);
    }
}
