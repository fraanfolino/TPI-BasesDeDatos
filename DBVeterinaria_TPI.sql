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

ALTER VIEW VW_MascotasActivas AS
SELECT M.IDMascota, M.Nombre AS NombreMascota, M.Tipo, M.Raza, M.Sexo, M.FechaNacimiento, M.Peso,
D.Nombre AS NombreDueño, D.Apellido AS ApellidoDueño, D.Telefono, D.Correo, D.Domicilio
FROM Mascotas AS M
INNER JOIN Dueños AS D ON M.DniDueño = D.Dni
WHERE M.Activo = 1 AND D.Activo = 1;

SELECT * FROM VW_MascotasActivas

----------------- VISTA DE USUARIOS CON ROLES -----------------
ALTER VIEW VW_UsuariosRoles AS
SELECT U.Usuario, U.Clave, U.Activo, R.Nombre AS Rol FROM Usuarios U
INNER JOIN Rol R ON U.IDRol = R.IDRol

SELECT * FROM VW_UsuariosRoles
----------------------------------------------------------------



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