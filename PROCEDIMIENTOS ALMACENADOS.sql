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
	IF (SELECT COUNT(*) FROM Usuarios WHERE Usuario =  @User) = 0 
	BEGIN
		RAISERROR('El usuario ingresado no existe', 16, 1);
		RETURN
	END
	ELSE
	BEGIN
		UPDATE Usuarios 
		SET Clave = @Pass 
		WHERE Usuario = @User;
	END
END
GO
-----------------------------------------------------------------------------------------
---------------------------- REGISTRAR COBRO --------------------------------------------
CREATE OR ALTER PROCEDURE SP_RegistrarCobro
    @IDFicha BIGINT,
    @LegajoRecepcionista BIGINT,
    @FormaPago VARCHAR(30),
    @Costo DECIMAL(10,2)
AS
BEGIN
    DECLARE @ExisteFicha INT;
    DECLARE @ExisteRecepcionista INT;
    DECLARE @CobroExistente INT;

    SELECT @ExisteFicha = IDFicha FROM FichaConsulta WHERE IDFicha = @IDFicha AND Activo = 1;

    IF @ExisteFicha IS NULL
    BEGIN
        RAISERROR('Error, no se encontró el turno.', 16, 1);
        RETURN;
    END

    SELECT @ExisteRecepcionista = Legajo FROM Recepcionistas WHERE Legajo = @LegajoRecepcionista AND Activo = 1;

    IF @ExisteRecepcionista IS NULL
    BEGIN
        RAISERROR('Error, el recepcionista no existe o está inactivo.', 16, 1);
        RETURN;
    END

    SELECT @CobroExistente = IDCobro FROM Cobros WHERE IDFicha = @IDFicha AND Activo = 1;

    IF @CobroExistente IS NOT NULL
    BEGIN
        RAISERROR('Error, ya se registró un cobro para este turno.', 16, 1);
        RETURN;
    END

    IF @Costo <= 0
    BEGIN
        RAISERROR('Error, el costo debe ser mayor a 0.', 16, 1);
        RETURN;
    END

    INSERT INTO Cobros (IDFicha, LegajoRecepcionista, FormaPago, Costo, Activo)
    VALUES (@IDFicha, @LegajoRecepcionista, @FormaPago, @Costo, 1);
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
    DECLARE @CantidadDueños INT;
    DECLARE @CantidadMascotas INT;

    SELECT @CantidadDueños = COUNT(*) FROM Dueños WHERE Dni = @DniDueño AND Activo = 1;

    IF @CantidadDueños = 0
    
	BEGIN
        RAISERROR('Error: El dueño no existe o está inactivo.', 16, 1);
        RETURN;
    END;

    SELECT @CantidadMascotas = COUNT(*) FROM Mascotas
    WHERE DniDueño = @DniDueño
      AND Nombre = @Nombre
      AND Tipo = @Tipo
      AND Raza = @Raza
      AND FechaNacimiento = @FechaNacimiento
      AND Activo = 1;

    
    IF @CantidadMascotas > 0
    BEGIN
        RAISERROR('Error: Ya existe una mascota registrada con esos datos para este dueño.', 16, 1);
        RETURN;
    END;

   
    IF @FechaNacimiento >= GETDATE()
    BEGIN
        RAISERROR('Error: La fecha de nacimiento debe ser anterior a la fecha actual.', 16, 1);
        RETURN;
    END;

  
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
------------------------------ CREAR USUARIO -----------------------------------
CREATE OR ALTER PROCEDURE SP_CrearUsuario(
	@Usuario varchar(25),
	@IDRol int,
	@Clave varchar(255)
) AS
BEGIN
	BEGIN TRY

		IF(SELECT COUNT(*) FROM Usuarios WHERE Usuario = @Usuario) > 0
		BEGIN
			RAISERROR ('YA EXISTE USUARIO REGISTRADO CON ESE NOMBRE DE USUARIO.', 16, 1)
			RETURN
		END

		IF (SELECT COUNT(*) FROM Rol WHERE IDRol = @IDRol) < 1 
		BEGIN
			RAISERROR ('EL ROL INGRESADO NO EXISTE.', 16, 1)
			RETURN
		END

		INSERT INTO Usuarios (Usuario, IDRol, Clave) 
		VALUES (@Usuario, @IDRol, @Clave)

	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
END;
GO
--------------------------------------------------------------------------------
---------------------------- AGREGAR DUEÑO -------------------------------------
CREATE OR ALTER PROCEDURE SP_AgregarDueño(
	@Dni varchar(10),
	@Nombre varchar(25),
	@Apellido varchar(25),
	@Telefono varchar(20),
	@Correo varchar(50),
	@Domicilio varchar(50)
) AS
BEGIN
	BEGIN TRY
	
		IF(SELECT COUNT(*) FROM Dueños WHERE Dni = @Dni) > 0
		BEGIN
			RAISERROR ('YA EXISTE DUEÑO CON ESE DNI.', 16, 1)
			RETURN
		END

		INSERT INTO Dueños (Dni, Nombre, Apellido, Telefono, Correo, Domicilio) 
		VALUES (@Dni, @Nombre, @Apellido, @Telefono, @Correo, @Domicilio)
		PRINT('DUEÑO AGREGADO CORRECTAMENTE.')

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

 
    SELECT @CantidadVeterinarios = COUNT(*) FROM Veterinarios WHERE Matricula = @MatriculaVeterinario AND Activo = 1;

    
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

   
    SELECT @CantidadVeterinarios = COUNT(*) FROM Veterinarios WHERE Matricula = @MatriculaVeterinario;

    
    IF @CantidadVeterinarios = 0
    BEGIN
        RAISERROR('Error: El veterinario no existe.', 16, 1);
        RETURN;
    END;

    SELECT * FROM VW_FichasConDiagnostico
    WHERE MatriculaVeterinario = @MatriculaVeterinario;
END;
GO
------------------------------------------------------------------------------------------
-----------------------FILTRAR CONSULTAS COBRADAS ENTRE DOS FECHA-------------------------
CREATE OR ALTER PROCEDURE sp_ConsultasEntreFechas
    @Desde DATETIME,
    @Hasta DATETIME
AS
BEGIN
    SELECT (D.Nombre + ', ' + D.Apellido) AS Dueño, 
			M.Nombre AS Mascota, 
			FC.Descripcion AS Consulta, 
			C.Costo,
			T.FechaHora AS Fecha
    FROM Cobros C
		INNER JOIN FichaConsulta FC ON C.IDFicha = FC.IDFicha
		INNER JOIN Turnos T ON FC.IDTurno = T.IDTurno
		INNER JOIN Mascotas M ON M.IDMascota = T.IDMascota
		INNER JOIN Dueños D ON M.DniDueño = D.Dni
    WHERE 
        C.Activo = 1
        AND T.FechaHora BETWEEN @Desde AND @Hasta
END;
GO

