
package com.desafio.validador.model;

import java.util.List;

public class PasswordResponse {
    private boolean valido;
    private List<String> motivos;

    public PasswordResponse(boolean valido, List<String> motivos) {
        this.valido = valido;
        this.motivos = motivos;
    }

    public boolean isValido() {
        return valido;
    }

    public List<String> getMotivos() {
        return motivos;
    }
}
