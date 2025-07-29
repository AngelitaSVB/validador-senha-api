package com.desafio.validador.model;

import lombok.Data;
import lombok.AllArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
public class PasswordResponse {
    private boolean valido;
    private List<String> motivos;
}
