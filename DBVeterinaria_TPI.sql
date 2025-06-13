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
    IDTurno BIGINT NOT NULL FOREIGN KEY REFERENCES Turnos(IDTurno),
    LegajoRecepcionista BIGINT NOT NULL FOREIGN KEY REFERENCES Recepcionistas(Legajo), 
    FormaPago VARCHAR(30),
    Costo DECIMAL(10,2), 
    Activo BIT DEFAULT 1
);
GO


use DBVeterinaria_TPI
GO

-- ===============================================================================
-- ===============================================================================
-- =======================[   V I A S T A S   ]===================================
-- ===============================================================================
-- ===============================================================================


---------------------VISTA MASCOTAS ACTIVAS CON DUEÑO-----------------------------
CREATE VIEW VW_MascotasActivas AS
SELECT M.IDMascota, M.Nombre AS NombreMascota, M.Tipo, M.Raza, M.Sexo, M.FechaNacimiento, M.Peso,
D.Nombre AS NombreDueño, D.Apellido AS ApellidoDueño, D.Telefono, D.Correo, D.Domicilio
FROM Mascotas AS M
INNER JOIN Dueños AS D ON M.DniDueño = D.Dni
WHERE M.Activo = 1 AND D.Activo = 1;
GO
-----------------------------------------------------------------------------------
----------------- VISTA DE USUARIOS CON ROLES -------------------------------------
CREATE VIEW VW_UsuariosRoles AS
SELECT U.Usuario, U.Clave, U.Activo, R.Nombre AS Rol FROM Usuarios U
INNER JOIN Rol R ON U.IDRol = R.IDRol
GO
-----------------------------------------------------------------------------------
--------------VISTA DE MASCOTAS CON SU ULTIMA CONSULTA-----------------------------
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
JOIN (
    SELECT FC.*, T.IDMascota
    FROM FichaConsulta FC
    JOIN Turnos T ON FC.IDTurno = T.IDTurno
    WHERE FC.IDFicha IN (
        SELECT TOP 1 FC2.IDFicha
        FROM FichaConsulta FC2
        JOIN Turnos T2 ON FC2.IDTurno = T2.IDTurno
        WHERE T2.IDMascota = T.IDMascota
        ORDER BY FC2.IDFicha DESC
    )
) FC ON FC.IDMascota = M.IDMascota
JOIN Turnos T ON T.IDTurno = FC.IDTurno;
GO
----------------------------------------------------------------------------------------
------------- TURNOS PENDIENTES --------------------------------------------------------
CREATE VIEW VW_TurnosPendientes AS
SELECT T.IDTurno, (V.Apellido + ', ' + V.Nombre) AS Veterinario, M.Nombre AS Mascota, FechaHora FROM Turnos T
INNER JOIN Veterinarios V ON T.MatriculaVeterinario = V.Matricula
INNER JOIN Mascotas M ON T.IDMascota = M.IDMascota
WHERE T.Estado like 'Pendiente';
GO
----------------------------------------------------------------------------------------
------------ Vista Fichas con diagnostico por veterinario--------------------------------
CREATE VIEW VW_FichasConDiagnostico AS
SELECT 
    FC.IDFicha, 
    FC.Descripcion AS Diagnostico, 
    FC.Activo, 
    T.IDTurno, 
    T.FechaHora, 
    V.Matricula AS MatriculaVeterinario, 
    V.Nombre AS NombreVeterinario, 
    V.Apellido AS ApellidoVeterinario
FROM FichaConsulta FC
INNER JOIN Turnos T ON FC.IDTurno = T.IDTurno
INNER JOIN Veterinarios V ON T.MatriculaVeterinario = V.Matricula
WHERE FC.Activo = 1;
GO
----------------------------------------------------------------------------------------

-- =====================================================================================
-- =====================================================================================
-- =======================[   P R O C E D I M I E N T O S   ]===========================
-- =====================================================================================
-- =====================================================================================

------------------------ CAMBIAR CONTRASEÑA DE USUARIO ---------------------------------
CREATE OR ALTER PROCEDURE SP_CambiarClave(
	@User VARCHAR(25),
  	@Pass VARCHAR(255)
)
AS
BEGIN
	IF (SELECT COUNT(*) FROM Usuarios WHERE Usuario =  @User) > 0
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
GO
-----------------------------------------------------------------------------------------
---------------------------- REGISTRAR COBRO --------------------------------------------
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

	IF @Costo <= 0
    BEGIN
        RAISERROR('Error, el costo debe ser mayor a 0.', 16, 1);
        RETURN;
    END

    INSERT INTO Cobros (IDTurno, LegajoRecepcionista, FormaPago, Costo)
    VALUES (@IDTurno, @LegajoRecepcionista, @FormaPago, @Costo);
END;
GO
-----------------------------------------------------------------------------------------
-------------------------------AGREGAR MASCOTA-------------------------------------------
CREATE OR ALTER PROCEDURE sp_AgregarMascota
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
    IF NOT EXISTS (SELECT 1 FROM Dueños WHERE Dni = @DniDueño AND Activo = 1)
    BEGIN
        RAISERROR('Error: El dueño no existe o está inactivo.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM Mascotas
        WHERE DniDueño = @DniDueño
          AND Nombre = @Nombre
          AND Tipo = @Tipo
          AND Raza = @Raza
          AND FechaNacimiento = @FechaNacimiento
          AND Activo = 1
    )
    BEGIN
        RAISERROR('Error: Ya existe una mascota registrada con esos datos para este dueño.', 16, 1);
        RETURN;
    END

    IF @FechaNacimiento >= GETDATE()
    BEGIN
        RAISERROR('Error: La fecha de nacimiento debe ser anterior a la fecha actual.', 16, 1);
        RETURN;
    END

    INSERT INTO Mascotas (DniDueño, Nombre, Edad, FechaNacimiento, Peso, Tipo, Raza, Sexo, FechaRegistro, Activo)
    VALUES (@DniDueño, @Nombre, @Edad, @FechaNacimiento, @Peso, @Tipo, @Raza, @Sexo, GETDATE(), 1);

    PRINT 'Mascota registrada correctamente.';
END;
GO
---------------------------------------------------------------------------
-------------- REGISTRAR RECEPCIONISTA -----------------------------------
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

		DECLARE @User varchar(25)
		Select @User = Usuario from Usuarios WHERE Usuario like @Usuario 
		IF @User IS NULL
		BEGIN
			RAISERROR ('NO EXISTE USUARIO REGISTRADO CON ESE NOMBRE', 16, 1)
		END
		

		IF(SELECT COUNT(*) FROM Recepcionistas WHERE Usuario like @Usuario) > 0
		BEGIN
			RAISERROR ('YA EXISTE RECEPCIONISTA CON ESE USUARIO', 16, 1)
		END

		IF(SELECT COUNT(*) FROM Recepcionistas WHERE Dni like @Dni) > 0
		BEGIN
			RAISERROR ('YA EXISTE RECEPCIONISTA CON ESE D.N.I.', 16, 1)
		END

		INSERT INTO Recepcionistas (Usuario, Nombre, Apellido, Dni, Telefono, Correo) 
		VALUES (@Usuario, @Nombre, @Apellido, @Dni, @Telefono, @Correo)

	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
END;
GO
--------------------------------------------------------------------------------
---------------------- REGISTRAR VETERINARIO -----------------------------------
CREATE PROCEDURE SP_registrarVeterinario(
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

		DECLARE @User varchar(25)
		Select @User = Usuario from Usuarios WHERE Usuario like @Usuario 
		IF @User IS NULL
		BEGIN
			RAISERROR ('NO EXISTE USUARIO REGISTRADO CON ESE NOMBRE', 16, 1)
		END
		

		IF(SELECT COUNT(*) FROM Veterinarios WHERE Usuario like @Usuario) > 0
		BEGIN
			RAISERROR ('YA EXISTE VETERINARIO CON ESE USUARIO', 16, 1)
		END

		IF(SELECT COUNT(*) FROM Veterinarios WHERE Dni like @Dni) > 0
		BEGIN
			RAISERROR ('YA EXISTE VETERINARIO CON ESE D.N.I.', 16, 1)
		END

		INSERT INTO Veterinarios (Matricula , Usuario, Nombre, Apellido, Dni, Telefono, Correo) 
		VALUES (@Matricula, @Usuario, @Nombre, @Apellido, @Dni, @Telefono, @Correo)

	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
END;
GO
---------------------------------------------------------------------------------
------------------------------------REGISTRAR TURNO------------------------------
GO
CREATE OR ALTER PROCEDURE SP_RegistrarTurno
    @MatriculaVeterinario VARCHAR(10),
    @IDMascota BIGINT,
    @FechaHora DATETIME,
    @Estado VARCHAR(20), 
    @Activo BIT           
AS
BEGIN
    
    DECLARE @CantidadVeterinarios INT;
    DECLARE @CantidadMascotas INT;

 
    SELECT @CantidadVeterinarios = COUNT(*)
    FROM Veterinarios
    WHERE Matricula = @MatriculaVeterinario AND Activo = 1;

    
    IF @CantidadVeterinarios = 0
    BEGIN
        RAISERROR('No se puede registrar el turno. El veterinario no se encuentra o está inactivo.', 16, 1);
        RETURN;
    END;

  
    SELECT @CantidadMascotas = COUNT(*)
    FROM Mascotas
    WHERE IDMascota = @IDMascota AND Activo = 1;

 
    IF @CantidadMascotas = 0
    BEGIN
        RAISERROR('No se puede registrar el turno. La mascota no se encuentra o está inactiva.', 16, 1);
        RETURN;
    END;

	--ultimo cambio aca, funciona bien
	DECLARE @TurnosFechaHora datetime;

	SELECT @TurnosFechaHora = COUNT(*)
    FROM Turnos
    WHERE MatriculaVeterinario = @MatriculaVeterinario
      AND FechaHora            = @FechaHora
      AND Activo               = 1;

    IF @TurnosFechaHora > 0
    BEGIN
        RAISERROR('No se puede registrar el turno. El veterinario ya tiene un turno activo en esa fecha y hora.', 16, 1);
        RETURN;
    END
	--revisar

    INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora, Estado, Activo)
    VALUES (@MatriculaVeterinario, @IDMascota, @FechaHora, @Estado, @Activo);

    PRINT 'Turno registrado correctamente.';
END;

GO
------------------------------------------------------------------------------------------
---------------------------------OBTENER FICHAS POR VETERINARIO----------------------------
CREATE OR ALTER PROCEDURE SP_ObtenerFichasPorVeterinario
    @MatriculaVeterinario VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CantidadVeterinarios INT;

   
    SELECT @CantidadVeterinarios = COUNT(*)
    FROM Veterinarios
    WHERE Matricula = @MatriculaVeterinario;

    
    IF @CantidadVeterinarios = 0
    BEGIN
        RAISERROR('Error: El veterinario no existe.', 16, 1);
        RETURN;
    END;

    SELECT * FROM VW_FichasConDiagnostico
    WHERE MatriculaVeterinario = @MatriculaVeterinario;
END;
GO
----------------------------------------------------------------------------------

-- ===============================================================================
-- ===============================================================================
-- =======================[   T R I G G E R S   ]=================================
-- ===============================================================================
-- ===============================================================================

-----------------------DESACTIVAR COBRO AL ELIMINAR TURNO--------------------------
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
------------------------------------------------------------------------------------
------------------------VALIDAR SI MASCOTA Y VETERINARIO ESTAN INACTIVOS------------
CREATE OR ALTER TRIGGER trg_ValidarTurno
ON Turnos
AFTER INSERT
AS
BEGIN
    DECLARE @CantidadVeterinariosInactivos INT;
    DECLARE @CantidadMascotasInactivas INT;


    SELECT @CantidadVeterinariosInactivos = COUNT(*)
    FROM inserted i
    INNER JOIN Veterinarios v ON i.MatriculaVeterinario = v.Matricula
    WHERE v.Activo = 0;

   
    IF @CantidadVeterinariosInactivos > 0
    BEGIN
        RAISERROR('No se puede insertar turno. El veterinario está inactivo.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    SELECT @CantidadMascotasInactivas = COUNT(*)
    FROM inserted i
    INNER JOIN Mascotas m ON i.IDMascota = m.IDMascota
    WHERE m.Activo = 0;

   
    IF @CantidadMascotasInactivas > 0
    BEGIN
        RAISERROR('No se puede insertar turno. La mascota está inactiva.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO
-----------------------------------------------------------------------------------
------------------ USAR TURNO ELIMINADO CON OTRA MASCOTA --------------------------
GO
CREATE OR ALTER TRIGGER tg_asignarTurnoExistente
ON Turnos
INSTEAD OF INSERT
AS 
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			-- CORROBORAMOS QUE LA FECHA NO ESTE ASIGNADO A UN ANIMAL
			DECLARE @fechaTurno DATETIME
			DECLARE @veterinario varchar(10)
			DECLARE @mascota int
			SELECT @fechaTurno = FechaHora, @veterinario = MatriculaVeterinario, @mascota = IDMascota FROM inserted

			IF (SELECT COUNT(*) FROM Turnos WHERE FechaHora = @fechaTurno AND MatriculaVeterinario = @veterinario) > 0
			BEGIN
				IF(SELECT Activo FROM Turnos WHERE FechaHora = @fechaTurno AND MatriculaVeterinario = @veterinario) = 1
				BEGIN
					RAISERROR ('YA SE ENCUENTRA ASIGNADO ESE TURNO.', 16, 1)	
				END
				ELSE 
				BEGIN
					UPDATE Turnos SET IDMascota = @mascota, Activo = 1 WHERE FechaHora = @fechaTurno AND MatriculaVeterinario = @veterinario
				END
			END
			ELSE
			BEGIN
				INSERT INTO Turnos (MatriculaVeterinario, IDMascota, FechaHora)
				VALUES (@veterinario, @mascota, @fechaTurno)
			END
	
		COMMIT TRANSACTION			   
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT ERROR_MESSAGE()
	END CATCH
END
GO
------------------------------------------------------------------------
----------------------ELIMINAR UN TURNO DE FORMA LOGICA---------------
CREATE OR ALTER TRIGGER tg_EliminarTurnoLogico
ON Turnos
INSTEAD OF DELETE
AS 
BEGIN
	UPDATE Turnos
	SET Activo = 0
	WHERE IDTurno IN (SELECT IDTurno FROM deleted)
END
GO
--------------------------------------------------------------------------------------
------------------------- Eliminar una mascota de forma logica -----------------------
CREATE OR ALTER TRIGGER tg_EliminarMascotaLogico
On Mascotas
INSTEAD OF DELETE
AS
BEGIN	
	UPDATE Mascotas
	SET Activo = 0
	WHERE IDMascota = (SELECT IDMascota From deleted)
END
GO
--------------------------------------------------------------------------------------
------------------------- Eliminar Dueños de forma logica ----------------------------
CREATE OR ALTER TRIGGER tg_EliminarDueñoLogico
On Dueños
INSTEAD OF DELETE
AS
BEGIN	
	UPDATE Dueños
	SET Activo = 0
	WHERE Dni = (SELECT Dni From deleted)
END
GO
----------------------------------------------------------------------------------------
------------------------- Eliminar FichaConsulta de forma logica -----------------------
CREATE OR ALTER TRIGGER tg_EliminarFichaConsultaLogico
On FichaConsulta
INSTEAD OF DELETE
AS
BEGIN	
	UPDATE FichaConsulta
	SET Activo = 0
	WHERE IDFicha = (SELECT IDFicha From deleted)
END
GO
----------------------------------------------------------------------------------------
------------------------- Eliminar FichaConsulta de forma logica -----------------------
CREATE OR ALTER TRIGGER tg_EliminarRecepcionistaLogico
On Recepcionistas
INSTEAD OF DELETE
AS
BEGIN	
	UPDATE Recepcionistas
	SET Activo = 0
	WHERE Legajo = (SELECT Legajo From deleted)
END
GO
--------------------------------------------------------------------------------------
------------------------- Eliminar Usuario de forma logica ---------------------------
CREATE OR ALTER TRIGGER tg_EliminarUsuarioLogico
On Usuarios
INSTEAD OF DELETE
AS
BEGIN	
	UPDATE Usuarios
	SET Activo = 0
	WHERE Usuario = (SELECT Usuario From deleted)
END
GO
--------------------------------------------------------------------------------------
------------------------- Eliminar Veterinario de forma logica -----------------------
CREATE OR ALTER TRIGGER tg_EliminarVeterinarioLogico
On Veterinarios
INSTEAD OF DELETE
AS
BEGIN	
	UPDATE Veterinarios
	SET Activo = 0
	WHERE Matricula = (SELECT Matricula From deleted)
END
GO
--------------------------------------------------------------------------------------
--------------------- Cambiar el estado de un turno atendido -------------------------
CREATE OR ALTER TRIGGER tg_cambiarEstadoTurno_FichaConsulta
ON FichaConsulta
AFTER INSERT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
		 DECLARE @idTurno int
		 Select @idTurno = IDTurno FROM INSERTED 
		
		UPDATE Turnos SET	Estado = 'REALIZADO' WHERE IDTurno = @idTurno
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END
GO
--------------------------------------------------------------------------------------
-------------------CAMBIAR EL ESTADO DEL TURNO SI SE REALIZA EL COBRO (COBROS)-------
CREATE OR ALTER TRIGGER tg_cambiarEstadoTurno_Cobros
ON Cobros
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalCobros INT;
    SELECT @TotalCobros = COUNT(*) FROM inserted;

    UPDATE t
    SET Estado = 'COBRADO'
    FROM Turnos AS t
    JOIN inserted AS i ON t.IDTurno = i.IDTurno
    WHERE t.Estado <> 'PENDIENTE';

    -- POR LAS DUDAS ESTO
	-- PQ si se mandan varios cobros a cambiar estaro, para ver si habia alguno pendiente y avisdar al user q no se actulizaon todos
	-- con uno funciona tb
    IF @@ROWCOUNT < @TotalCobros
    BEGIN
        PRINT 'Advertencia: Algunos turnos no se actualizaron porque están en estado PENDIENTE.';
    END
END;
GO

------------------------------------------------------------------------------------
------------------------- Eliminar Dueños de forma logica ----------------------------
---y ademas-------- NO ELIMINAR DUEÑO SI TIENE MASCOTA ACTIVA ------------------------
CREATE OR ALTER TRIGGER tg_EliminarDueñoLogico
ON Dueños
INSTEAD OF DELETE
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION

        DECLARE @dni VARCHAR(10)
        SELECT @dni = Dni FROM deleted

        -- ver si tiene le dueño mascotas q esten activ
        IF (SELECT COUNT(*) FROM Mascotas WHERE DniDueño = @dni AND Activo = 1) > 0
        BEGIN
            RAISERROR('El dueño tiene mascotas activas.', 16, 1)
        END
        ELSE
        BEGIN
            UPDATE Dueños
            SET Activo = 0
            WHERE Dni = @dni
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE()
    END CATCH
END
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
INSERT INTO Cobros (IDTurno, LegajoRecepcionista, FormaPago, Costo) VALUES 
(2, 100, 'Efectivo', 3500.00),
(2, 101, 'Tarjeta', 4500.00),
(3, 100, 'MercadoPago', 3800.00);

SELECT * FROM USUARIOS
SELECT * FROM VETERINARIOS
SELECT * FROM Turnos

 --------------------------- De aca para arriba para crear la bd ---------------------------





 --------------------------- -OTRAS / PRUEBAS ---------------------------
--INSERTS CON LOS STORED
--ASI SERIA EL INSERT CON EL SP
BEGIN TRANSACTION;
    EXEC sp_AgregarMascota @DniDueño='11111111', @Nombre='Firulais', @Edad=3, @FechaNacimiento='2022-01-15', @Peso=12.5, @Tipo='Perro', @Raza='Labrador', @Sexo='Macho';
    EXEC sp_AgregarMascota @DniDueño='11111111', @Nombre='Mishi',   @Edad=2, @FechaNacimiento='2023-03-10', @Peso=3.2,  @Tipo='Gato', @Raza='Siamés',   @Sexo='Hembra';
    EXEC sp_AgregarMascota @DniDueño='22222222', @Nombre='Toby',    @Edad=5, @FechaNacimiento='2020-07-01', @Peso=8.7,  @Tipo='Perro', @Raza='Beagle',   @Sexo='Macho';
    EXEC sp_AgregarMascota @DniDueño='33333333', @Nombre='Luna',    @Edad=1, @FechaNacimiento='2024-02-14', @Peso=4.0,  @Tipo='Gato',  @Raza='Persa',    @Sexo='Hembra';
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
