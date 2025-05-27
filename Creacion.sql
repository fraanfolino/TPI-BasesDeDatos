CREATE Database TPI_BasesDeDatos;

USE TPI_BasesDeDatos;


CREATE TABLE Dueño (
    IDDueño INT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL,
    Apellido VARCHAR(50) NOT NULL,
    DNI VARCHAR(20) UNIQUE NOT NULL,
	LEGAJO VARCHAR(20) UNIQUE NOT NULL,
    Telefono VARCHAR(20),
    Correo VARCHAR(100),
    Domicilio VARCHAR(150),
    CantMascotas INT,
    Activo SMALLINT DEFAULT 1
);

CREATE TABLE Mascota (
    IDMascota INT PRIMARY KEY,
    IDDueño INT NOT NULL FOREIGN KEY REFERENCES Dueño(IDDueño),
    Nombre VARCHAR(50) NOT NULL,
    Edad INT CHECK (Edad >= 0),
    FechaNacimiento DATE,
    Peso DECIMAL CHECK (Peso >= 1),
    Tipo VARCHAR(30),
    Raza VARCHAR(50),
    Sexo SMALLINT CHECK (Sexo IN (0,1)),
    Activo SMALLINT DEFAULT 1
	FechaRegistro DATETIME DEFAULT CURRENT_TIMESTAMP;
);



