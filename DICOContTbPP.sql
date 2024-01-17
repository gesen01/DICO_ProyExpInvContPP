CREATE TABLE DICOContTbPP (
       Estacion            INT                 NOT NULL,
      ,ID                  INT                 NULL
      ,MovCont             VARCHAR(30)         NULL
      ,MovContID           VARCHAR(20)         NULL
      ,FechaContable       DATETIME            NULL
      ,Debe                FLOAT               NULL
      ,Haber               FLOAT               NULL
      ,OrigenTipo          VARCHAR(5)          NULL
      ,Origen              VARCHAR(30)         NULL
      ,OrigenID            VARCHAR(20)         NULL
      ,Cuenta              VARCHAR(30)         NULL
      ,OModuloID           VARCHAR(20)         NULL
)