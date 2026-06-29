### Diagrama Entidad-Relación (Modelo Estrella - BI)

```mermaid
erDiagram
    %% Dimensiones
    Dim_Tiempo {
        int tiempo_anio PK
        int tiempo_mes PK
        int tiempo_cuatrimestre
        string tiempo_temporada
    }
    
    Dim_Cliente_Rango_Etario {
        int cliente_id PK
        string cliente_rango_etario
    }
    
    Dim_Agente_Rango_Etario {
        bigint agente_legajo PK
        string agente_rango_etario
    }
    
    Dim_Canal_Venta {
        int canal_venta_id PK
        string canal_venta_descripcion
    }
    
    Dim_Tipo_Servicio {
        int tipo_servicio_id PK
        string tipo_servicio_descripcion
    }
    
    Dim_Estado_Propuesta {
        int estado_id PK
        string estado_descripcion
    }
    
    Dim_Aspecto {
        int aspecto_id PK
        string aspecto_descripcion
    }

    %% Tablas de Hechos
    Hecho_Solicitud {
        bigint solicitud_numero PK
        int solicitud_anio FK
        int solicitud_mes FK
        date solicitud_fecha
        int solicitud_cliente FK
        int dias_anticipacion
        decimal solicitud_presupuesto_estimado
    }

    Hecho_Propuesta {
        bigint propuesta_numero PK
        bigint propuesta_solicitud_numero
        int emision_tiempo_anio FK
        int emision_tiempo_mes FK
        date fecha_emision
        int inicio_tiempo_anio FK
        int inicio_tiempo_mes FK
        bigint propuesta_agente FK
        int propuesta_estado FK
        decimal propuesta_importe_total
    }

    Hecho_Encuesta {
        bigint encuesta_codigo PK
        int aspecto_id PK, FK
        int encuesta_anio FK
        int encuesta_mes FK
        int encuesta_cliente FK
        bigint encuesta_agente FK
        int aspecto_puntaje
    }

    Hecho_Venta {
        bigint venta_numero PK
        int venta_anio FK
        int venta_mes FK
        int cliente_id FK
        int canal_venta_id FK
        int tipo_servicio_id FK
        decimal venta_total
    }

    %% Relaciones (Modelo Estrella)
    Dim_Tiempo ||--o{ Hecho_Solicitud : "asociado a (solicitud_anio, solicitud_mes)"
    Dim_Cliente_Rango_Etario ||--o{ Hecho_Solicitud : "realiza"

    Dim_Tiempo ||--o{ Hecho_Propuesta : "emitida en (emision_tiempo)"
    Dim_Tiempo ||--o{ Hecho_Propuesta : "inicia en (inicio_tiempo)"
    Dim_Agente_Rango_Etario ||--o{ Hecho_Propuesta : "creada por"
    Dim_Estado_Propuesta ||--o{ Hecho_Propuesta : "tiene estado"

    Dim_Tiempo ||--o{ Hecho_Encuesta : "respondida en (encuesta_anio, encuesta_mes)"
    Dim_Cliente_Rango_Etario ||--o{ Hecho_Encuesta : "evaluada por"
    Dim_Agente_Rango_Etario ||--o{ Hecho_Encuesta : "asociada al agente"
    Dim_Aspecto ||--o{ Hecho_Encuesta : "mide puntaje de"

    Dim_Tiempo ||--o{ Hecho_Venta : "facturada en (venta_anio, venta_mes)"
    Dim_Cliente_Rango_Etario ||--o{ Hecho_Venta : "pertenece al cliente"
    Dim_Canal_Venta ||--o{ Hecho_Venta : "ingresa por"
    Dim_Tipo_Servicio ||--o{ Hecho_Venta : "clasificada por"
