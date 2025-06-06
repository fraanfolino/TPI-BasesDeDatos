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
    IDTurno BIGINT NOT NULL FOREIGN KEY REFERENCES Turnos(IDTurno),
    LegajoRecepcionista BIGINT NOT NULL FOREIGN KEY REFERENCES Recepcionistas(Legajo), 
    FormaPago VARCHAR(30),
    Costo DECIMAL(10,2), 
    Activo BIT DEFAULT 1
);






---------------------------- VISTAS -----------------------

---------------------VISTA MASCOTAS ACTIVAS CON DUEÑO---------------------

ALTER VIEW VW_MascotasActivas AS
SELECT M.IDMascota, M.Nombre AS NombreMascota, M.Tipo, M.Raza, M.Sexo, M.FechaNacimiento, M.Peso,
D.Nombre AS NombreDueño, D.Apellido AS ApellidoDueño, D.Telefono, D.Correo, D.Domicilio
FROM Mascotas AS M
INNER JOIN Dueños AS D ON M.DniDueño = D.Dni
WHERE M.Activo = 1 AND D.Activo = 1;

SELECT * FROM VW_MascotasActivas

---------------------------------------------------------------

----------------- VISTA DE USUARIOS CON ROLES -----------------
ALTER VIEW VW_UsuariosRoles AS
SELECT U.Usuario, U.Clave, U.Activo, R.Nombre AS Rol FROM Usuarios U
INNER JOIN Rol R ON U.IDRol = R.IDRol

SELECT * FROM VW_UsuariosRoles
----------------------------------------------------------------

--------------VISTA DE MASCOTAS CON SU ULTIMA CONSULTA----------
CREATE VIEW VW_MascotasUltimaConsulta AS
SELECT 
    M.IDMascota,
    M.Nombre AS NombreMascota,
    M.DniDueño,
    FC.IDFicha,
    FC.Descripcion,
    FC.IDTurno,
    T.FechaHora
FROM Mascotas M
OUTER APPLY (
    SELECT TOP 1 FC.*
    FROM Turnos T
    JOIN FichaConsulta FC ON FC.IDTurno = T.IDTurno
    WHERE T.IDMascota = M.IDMascota
    ORDER BY FC.IDFicha DESC
) FC
JOIN Turnos T ON T.IDTurno = FC.IDTurno;
GO
----------------------------------------------------------------

------------- TURNOS PENDIENTES -------------------------------

CREATE VIEW VW_TurnosPendientes AS
SELECT T.IDTurno, (V.Apellido + ', ' + V.Nombre) AS Veterinario, M.Nombre AS Mascota, FechaHora FROM Turnos T
INNER JOIN Veterinarios V ON T.MatriculaVeterinario = V.Matricula
INNER JOIN Mascotas M ON T.IDMascota = M.IDMascota
WHERE T.Estado like 'Pendiente';
--------------------------------------------------------------


---------------- PROCEDIMIENTOS ALMACENADOS ----------------------

--------------- CAMBIAR CONTRASEÑA DE USUARIO --------------------
ALTER PROCEDURE SP_CambiarClave(
	@User VARCHAR(25),
  	@Pass VARCHAR(255)
)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Usuarios WHERE Usuario = @User)
	BEGIN
		UPDATE Usuarios 
		SET Clave = @Pass 
		WHERE Usuario = @User;
		PRINT 'Contraseña actualizada con exito.';
	END
	ELSE
	BEGIN
		RAISERROR('El usuario ingresado no existe', 16, 1);
	END
END
------------------------------------------------------------------


------------------- REGISTRAR COBRO ------------------------------
CREATE PROCEDURE SP_RegistrarCobro
    @IDTurno BIGINT,
    @LegajoRecepcionista BIGINT,
    @FormaPago VARCHAR(30),
    @Costo DECIMAL(10,2)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Turnos WHERE IDTurno = @IDTurno AND Activo = 1)
    BEGIN
        RAISERROR('Error, no se encontro el turno', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Recepcionistas WHERE Legajo = @LegajoRecepcionista AND Activo = 1)
    BEGIN
        RAISERROR('Error, el recepcionista no existe o esta inactivo.', 16, 1);
        RETURN;
    END

    INSERT INTO Cobros (IDTurno, LegajoRecepcionista, FormaPago, Costo)
    VALUES (@IDTurno, @LegajoRecepcionista, @FormaPago, @Costo);
END;
GO
------------------------------------------------------------------

	
---------------------AGREGAR MASCOTA------------------

ALTER PROCEDURE sp_AgregarMascota
    @DniDueño VARCHAR(10),
    @Nombre VARCHAR(25),
    @Edad INT,
    @FechaNacimiento DATETIME,
    @Peso DECIMAL(5,2),
    @Tipo VARCHAR(25),
    @Raza VARCHAR(25),
    @Sexo VARCHAR(20)
AS
BEGIN
   
    INSERT INTO Mascotas (DniDueño, Nombre, Edad, FechaNacimiento, Peso, Tipo, Raza, Sexo, FechaRegistro, Activo)
    VALUES (@DniDueño, @Nombre, @Edad, @FechaNacimiento, @Peso, @Tipo, @Raza, @Sexo, GETDATE(), 1);

    PRINT 'Mascota registrada correctamente.';
END;

---------------------------------------------------------------------------

-------------- REGISTRAR RECEPCIONISTA ---------------------------
CREATE PROCEDURE SP_registrarRecepcionista(
	@Usuario varchar(25),
	@Nombre varchar(25),
	@Apellido varchar(25),
	@Dni varchar(25),
	@Telefono varchar(20),
	@Correo varchar(50)
) AS
BEGIN
	BEGIN TRY
		--------- Verificamos si el usuario esta registrado en la tabla 'Usuarios' --------------
		DECLARE @User varchar(25)
		Select @User = Usuario from Usuarios WHERE Usuario like @Usuario 
		IF @User IS NULL
		BEGIN
			RAISERROR ('NO EXISTE USUARIO REGISTRADO CON ESE NOMBRE', 16, 1)
		END
		
		--------- Verificamos que el Usuario no este regitrado con otra Recepcionista------------
		IF(SELECT COUNT(*) FROM Recepcionistas WHERE Usuario like @Usuario) > 0
		BEGIN
			RAISERROR ('YA EXISTE RECEPCIONISTA CON ESE USUARIO', 16, 1)
		END
		--------- Verificamos que no se encuentre registrada la Recepcionista ---------------
		IF(SELECT COUNT(*) FROM Recepcionistas WHERE Dni like @Dni) > 0
		BEGIN
			RAISERROR ('YA EXISTE RECEPCIONISTA CON ESE D.N.I.', 16, 1)
		END
		---------- Registramos los Datos -------------------
		INSERT INTO Recepcionistas (Usuario, Nombre, Apellido, Dni, Telefono, Correo) VALUES (@Usuario, @Nombre, @Apellido, @Dni, @Telefono, @Correo)

	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
END;

---------------------------------------------------------------------------
---------------------- REGISTRAR VETERINARIO ------------------------------
---------------------------------------------------------------------------

alter PROCEDURE SP_registrarVeterinario(
	@Matricula varchar(10),
	@Usuario varchar(25),
	@Nombre varchar(25),
	@Apellido varchar(25),
	@Dni varchar(25),
	@Telefono varchar(20),
	@Correo varchar(50)
) AS
BEGIN
	BEGIN TRY
		--------- Verificamos si el usuario esta registrado en la tabla 'Usuarios' --------------
		DECLARE @User varchar(25)
		Select @User = Usuario from Usuarios WHERE Usuario like @Usuario 
		IF @User IS NULL
		BEGIN
			RAISERROR ('NO EXISTE USUARIO REGISTRADO CON ESE NOMBRE', 16, 1)
		END
		
		--------- Verificamos que el Usuario no este registrado con otro Veterinario ------------
		IF(SELECT COUNT(*) FROM Veterinarios WHERE Usuario like @Usuario) > 0
		BEGIN
			RAISERROR ('YA EXISTE VETERINARIO CON ESE USUARIO', 16, 1)
		END
		--------- Verificamos que no se encuentre registrada el veterinario ---------------
		IF(SELECT COUNT(*) FROM Veterinarios WHERE Dni like @Dni) > 0
		BEGIN
			RAISERROR ('YA EXISTE VETERINARIO CON ESE D.N.I.', 16, 1)
		END
		---------- Registramos los Datos -------------------
		INSERT INTO Veterinarios (Matricula , Usuario, Nombre, Apellido, Dni, Telefono, Correo) 
		VALUES (@Matricula, @Usuario, @Nombre, @Apellido, @Dni, @Telefono, @Correo)

	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
END;
---------------------------------------------------------------------------

------------------------------- TRIGGERS ----------------------------------
---------------DESACTIVAR COBRO AL ELIMINAR TURNO--------------------------
CREATE TRIGGER TRG_DesactivarCobro_AlEliminarTurno
ON Turnos
AFTER DELETE
AS
BEGIN
    UPDATE Cobros
    SET Activo = 0
    WHERE IDTurno IN (SELECT IDTurno FROM DELETED);
END;
GO
---------------------------------------------------------------------------
------------------------VALIDAR SI MASCOTA Y VETERINARIO ESTAN INACTIVOS------------------------------
CREATE OR ALTER TRIGGER trg_ValidarTurno
ON Turnos
AFTER INSERT
AS
BEGIN
 
  IF EXISTS(SELECT 1 FROM inserted i INNER JOIN Veterinarios v ON i.MatriculaVeterinario = v.Matricula WHERE v.Activo = 0)
  
  BEGIN
   
   RAISERROR('No se puede insertar turno. El veterinario está inactivo.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
  
  END;

  IF EXISTS(SELECT 1 FROM inserted i INNER JOIN Mascotas m ON i.IDMascota = m.IDMascota WHERE m.Activo = 0)
  BEGIN

    RAISERROR('No se puede insertar turno. La mascota está inactiva.', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;

  END;
END;
GO




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
INSERT INTO Veterinarios (Matricula, Usuario, Nombre, Apellido, Dni, Telefono, Correo) VALUES 
('VET001', 'vet_jlopez', 'Juan', 'Lopez', '30111222', '1122334455', 'jlopez@vet.com'),
('VET002', 'vet_mgomez', 'Maria', 'Gomez', '30999888', '1133445566', 'mgomez@vet.com'),
('VET003', 'vet_rsosa', 'Ricardo', 'Sosa', '32123456', '1144556677', 'rsosa@vet.com');

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

-- TURNOS (3 anteriores a la fecha de hoy)
INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora) VALUES 
('VET001', 1, '2025-05-20 10:00'), -- anterior
('VET002', 2, '2025-05-25 11:00'), -- anterior
('VET003', 3, '2025-05-10 09:00'), -- anterior
('VET001', 1, '2025-06-10 10:00'),
('VET002', 2, '2025-06-11 11:00'),
('VET003', 3, '2025-06-12 09:00'),
('VET001', 4, '2025-06-13 13:00'),
('VET002', 4, '2025-06-14 15:00');

-- FICHAS CONSULTA para los 3 turnos anteriores
INSERT INTO FichaConsulta (IDTurno, Descripcion) VALUES 
(1, 'Consulta general, se desparasitó al paciente.'),
(2, 'Vacunación anual realizada sin inconvenientes.'),
(3, 'Se trató una infección leve en el oído.');

-- COBROS para los turnos anteriores
INSERT INTO Cobros (IDTurno, LegajoRecepcionista, FormaPago, Costo) VALUES 
(1, 100, 'Efectivo', 3500.00),
(2, 101, 'Tarjeta', 4500.00),
(3, 100, 'MercadoPago', 3800.00);