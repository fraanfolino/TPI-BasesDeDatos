--- ELIMINACION DE LA BASE DE DATOS -----
--ALTER DATABASE DBVeterinaria_TPI SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--DROP DATABASE DBVeterinaria_TPI;

CREATE DATABASE DBVeterinaria_TPI COLLATE Latin1_General_CI_AI;
GO
USE DBVeterinaria_TPI;
GO

---- AGUSTIN ------
CREATE TABLE Rol(
	IDRol INT PRIMARY KEY IDENTITY (1,1),
	Nombre VARCHAR(25) NOT NULL
);
GO

CREATE TABLE Usuarios(
    Usuario VARCHAR(25) PRIMARY KEY,
    IDRol INT NOT NULL FOREIGN KEY REFERENCES Rol(IDRol),
    Clave VARCHAR(255) NOT NULL,
    Activo BIT DEFAULT 1
);
GO

---- FRANCO -----
CREATE TABLE Dueños(
    Dni VARCHAR(10) PRIMARY KEY ,
    Nombre VARCHAR(25) NOT NULL,
    Apellido VARCHAR(25) NOT NULL,
    Telefono VARCHAR(20),
    Correo VARCHAR(50) UNIQUE,
    Domicilio VARCHAR(50),
    Activo BIT DEFAULT 1
);
GO

---- SOL ----
CREATE TABLE Veterinarios(
    Matricula VARCHAR(10) PRIMARY KEY,
    Usuario VARCHAR(25) NOT NULL FOREIGN KEY REFERENCES Usuarios(Usuario),
    Nombre VARCHAR(25) NOT NULL,
    Apellido VARCHAR(25) NOT NULL,
    Dni VARCHAR(10) NOT NULL UNIQUE,
    Telefono VARCHAR(20),
    Correo VARCHAR(50) UNIQUE,
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE Recepcionistas(
    Legajo BIGINT PRIMARY KEY IDENTITY (100,1),
    Usuario VARCHAR(25) NOT NULL FOREIGN KEY REFERENCES Usuarios(Usuario),
    Nombre VARCHAR(25) NOT NULL,
    Apellido VARCHAR(25) NOT NULL,
    Dni VARCHAR(10) NOT NULL UNIQUE,
    Telefono VARCHAR(20),
    Correo VARCHAR(50) UNIQUE,
    Activo BIT DEFAULT 1
);
GO


CREATE TABLE Turnos(
    IDTurno BIGINT PRIMARY KEY IDENTITY (1,1),
    MatriculaVeterinario VARCHAR(10) NOT NULL FOREIGN KEY REFERENCES Veterinarios(Matricula), 
    IDMascota BIGINT NOT NULL, 
    FechaHora DATETIME,
	Estado VARCHAR(20) DEFAULT 'PENDIENTE',
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE FichaConsulta(
    IDFicha INT PRIMARY KEY IDENTITY (1,1),
    IDTurno BIGINT NOT NULL FOREIGN KEY REFERENCES Turnos(IDTurno),
    Descripcion VARCHAR(500) NOT NULL,
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE Mascotas(
    IDMascota BIGINT PRIMARY KEY IDENTITY (1,1),
    DniDueño VARCHAR(10) NOT NULL FOREIGN KEY REFERENCES Dueños(Dni),
    Nombre VARCHAR(25) NOT NULL,
    Edad INT,
    FechaNacimiento DATETIME,
    Peso DECIMAL(5,2), 
    Tipo VARCHAR(25),
    Raza VARCHAR(25),
    Sexo VARCHAR(20),
    FechaRegistro DATETIME DEFAULT GETDATE(),
    Activo BIT DEFAULT 1
);
GO

ALTER TABLE Turnos
ADD CONSTRAINT FK_Turnos_Mascotas
FOREIGN KEY (IDMascota) REFERENCES Mascotas(IDMascota);
GO

---- NICOLAS ------
CREATE TABLE Cobros(
    IDCobro BIGINT PRIMARY KEY IDENTITY (1,1),
    IDFicha INT NOT NULL FOREIGN KEY REFERENCES FichaConsulta(IDFicha),
    LegajoRecepcionista BIGINT NOT NULL FOREIGN KEY REFERENCES Recepcionistas(Legajo), 
    FormaPago VARCHAR(30),
    Costo DECIMAL(10,2), 
    Activo BIT DEFAULT 1
);
GO

--------------------------------------------------------------------------------------

-- =================================================================================
-- =================================================================================
-- =======================[   R E G I S T R O S   ]=================================
-- =================================================================================
-- =================================================================================

-- ROL
INSERT INTO Rol (Nombre) VALUES ('Recepcionista'), ('Veterinario');

-- USUARIOS
INSERT INTO Usuarios (Usuario, IDRol, Clave) VALUES 
('vet_jlopez', 2, 'clave123'), 
('vet_mgomez', 2, 'clave123'), 
('vet_rsosa', 2, 'clave123'),
('recep_sjuarez', 1, 'clave123'),
('recep_mruiz', 1, 'clave123');

-- VETERINARIOS
INSERT INTO Veterinarios (Matricula, Usuario, Nombre, Apellido, Dni, Telefono, Correo, Activo) VALUES 
('VET001', 'vet_jlopez', 'Juan', 'Lopez', '30111222', '1122334455', 'jlopez@vet.com', 1),
('VET002', 'vet_mgomez', 'Maria', 'Gomez', '30999888', '1133445566', 'mgomez@vet.com', 1),
('VET003', 'vet_rsosa', 'Ricardo', 'Sosa', '32123456', '1144556677', 'rsosa@vet.com', 1);

-- RECEPCIONISTAS
INSERT INTO Recepcionistas (Usuario, Nombre, Apellido, Dni, Telefono, Correo) VALUES 
('recep_sjuarez', 'Sofía', 'Juarez', '27000111', '1177889900', 'sjuarez@vet.com'),
('recep_mruiz', 'Marcos', 'Ruiz', '28000222', '1166778899', 'mruiz@vet.com');

-- DUEÑOS
INSERT INTO Dueños (Dni, Nombre, Apellido, Telefono, Correo, Domicilio) VALUES 
('11111111', 'Carlos', 'Perez', '1111222233', 'cperez@mail.com', 'Av. Siempre Viva 123'),
('22222222', 'Lucia', 'Fernandez', '2222333344', 'lfernandez@mail.com', 'Calle Falsa 456'),
('33333333', 'Diego', 'Martinez', '3333444455', 'dmartinez@mail.com', 'Av. Mitre 789');

-- MASCOTAS (Carlos tiene 2)
INSERT INTO Mascotas (DniDueño, Nombre, Edad, FechaNacimiento, Peso, Tipo, Raza, Sexo) VALUES 
('11111111', 'Firulais', 3, '2022-01-15', 12.5, 'Perro', 'Labrador', 'Macho'),
('11111111', 'Mishi', 2, '2023-03-10', 3.2, 'Gato', 'Siamés', 'Hembra'),
('22222222', 'Toby', 5, '2020-07-01', 8.7, 'Perro', 'Beagle', 'Macho'),
('33333333', 'Luna', 1, '2024-02-14', 4.0, 'Gato', 'Persa', 'Hembra');

-- TURNOS
INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora) VALUES ('VET003', 1, '2025-06-12 09:00');
INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora) VALUES ('VET001', 1, '2025-05-20 10:00'); 
INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora) VALUES ('VET002', 2, '2025-05-25 11:00'); 
INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora) VALUES ('VET003', 3, '2025-05-10 09:00'); 
INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora) VALUES ('VET001', 1, '2025-06-10 10:00');
INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora) VALUES ('VET002', 2, '2025-06-11 11:00');
INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora) VALUES ('VET001', 4, '2025-06-13 13:00');
INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora) VALUES ('VET002', 4, '2025-06-14 15:00');


-- FICHAS CONSULTA para los 3 turnos anteriores
INSERT INTO FichaConsulta (IDTurno, Descripcion) VALUES 
(2, 'Consulta general, se desparasitó al paciente.'),
(1, 'Vacunación anual realizada sin inconvenientes.'),
(3, 'Se trató una infección leve en el oído.');

-- COBROS para los turnos anteriores
INSERT INTO Cobros (IDFicha, LegajoRecepcionista, FormaPago, Costo) VALUES 
(2, 100, 'Efectivo', 3500.00),
(2, 101, 'Tarjeta', 4500.00),
(3, 100, 'MercadoPago', 3800.00);


 --------------------------- De aca para arriba para crear la bd ---------------------------

 --------------------------- -OTRAS / PRUEBAS ---------------------------
--INSERTS CON LOS STORED
--ASI SERIA EL INSERT CON EL SP
BEGIN TRANSACTION;
    EXEC sp_AgregarMascota @DniDueño='11111111', @Nombre='Firulais', @Edad=3, @FechaNacimiento='2022-01-15', @Peso=12.5, @Tipo='Perro', @Raza='Labrador', @Sexo='Macho';
    EXEC sp_AgregarMascota @DniDueño='11111111', @Nombre='Mishi',   @Edad=2, @FechaNacimiento='2023-03-10', @Peso=3.2,  @Tipo='Gato', @Raza='Siamés',   @Sexo='Hembra';
    EXEC sp_AgregarMascota @DniDueño='22222222', @Nombre='Toby',    @Edad=5, @FechaNacimiento='2020-07-01', @Peso=8.7,  @Tipo='Perro', @Raza='Beagle',   @Sexo='Macho';
    EXEC sp_AgregarMascota @DniDueño='33333333', @Nombre='Luna',    @Edad=1, @FechaNacimiento='2024-02-14', @Peso=4.0,  @Tipo='Gato',  @Raza='Persa',    @Sexo='Hembra';
    EXEC sp_AgregarMascota @DniDueño='11111111', @Nombre='Max',     @Edad=4, @FechaNacimiento='2021-08-20', @Peso=10.5, @Tipo='Perro', @Raza='Boxer',  @Sexo='Macho';
COMMIT;
GO
---------------------------REGISTRO TURNO ---------------------------------------
--USE DBVeterinaria_TPI;
GO
EXEC SP_RegistrarTurno 
    @MatriculaVeterinario = 'VET001', 
    @IDMascota = 2, 
    @FechaHora = '2025-04-07 10:00:00', 
    @Estado = 'CONFIRMADO', 
    @Activo = 1;
GO
---------------------------------------------------------------------------------
-----------COMPROBACION CARGAR DOS TURNOS MISMO DIA MISMO VETE-------------------
-- Primera
EXEC SP_RegistrarTurno
    @MatriculaVeterinario = 'VET001',
    @IDMascota            = 1,
    @FechaHora            = '2025-06-15 10:00',
    @Estado               = 'Pendiente',
    @Activo               = 1;
GO

-- Segunda q tendria q dar error
EXEC SP_RegistrarTurno
    @MatriculaVeterinario = 'VET001',
    @IDMascota            = 1,
    @FechaHora            = '2025-06-15 10:00',
    @Estado               = 'Pendiente',
    @Activo               = 1;
GO
---------------------------------------------------------------------------------




------------------------------ERRORES REPARACION----------------------------------------
--REPARAR ERRORES (esto repara el error q a veces no deja crear el stored
--CUANDO SALE UN ERROR COMO ESTE
--Msg 208, Level 16, State 6, Procedure sp_AgregarMascota, Line 3 [Batch Start Line 246]
--Invalid object name 'sp_AgregarMascota'.

--DROP PROCEDURE IF EXISTS SP_ObtenerFichasPorVeterinario;
--GO
--REPARAR ERRORES
--DROP PROCEDURE IF EXISTS sp_AgregarMascota;
--GO
--REPARAR ERRORES
--DROP PROCEDURE IF EXISTS SP_RegistrarTurno;
--GO
