use DBVeterinaria_TPI
GO

-- =====================================================================================
-- =====================================================================================
-- ===============================[   V I S T A S   ]===================================
-- =====================================================================================
-- =====================================================================================


-------------------------------- MASCOTAS ACTIVAS CON DUEÑO ----------------------------
CREATE VIEW VW_MascotasActivas AS
SELECT M.IDMascota, M.Nombre AS NombreMascota, M.Tipo, M.Raza, M.Sexo, M.FechaNacimiento, M.Peso,
D.Nombre AS NombreDueño, D.Apellido AS ApellidoDueño, D.Telefono, D.Correo, D.Domicilio
FROM Mascotas AS M
INNER JOIN Dueños AS D ON M.DniDueño = D.Dni
WHERE M.Activo = 1 AND D.Activo = 1;
GO

---------------------------------- USUARIOS CON ROLES ----------------------------------
CREATE VIEW VW_UsuariosRoles AS
SELECT U.Usuario, U.Clave, U.Activo, R.Nombre AS Rol FROM Usuarios U
INNER JOIN Rol R ON U.IDRol = R.IDRol
GO

---------------------------- MASCOTAS CON SU ULTIMA CONSULTA ---------------------------
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

--------------------------------- TURNOS PENDIENTES ------------------------------
CREATE VIEW VW_TurnosPendientes AS
SELECT T.IDTurno, (V.Apellido + ', ' + V.Nombre) AS Veterinario, M.Nombre AS Mascota, FechaHora FROM Turnos T
INNER JOIN Veterinarios V ON T.MatriculaVeterinario = V.Matricula
INNER JOIN Mascotas M ON T.IDMascota = M.IDMascota
WHERE T.Estado like 'Pendiente';
GO

------------------------ FICHAS CON DIAGNOSTICO POR VETERINARIO -----------------
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
-------------- DESCRIPCION COMPLETA DE LAS CONSULTAS COBRADAS --------------------

CREATE OR ALTER VIEW VW_ConsultasCobradas AS
SELECT (D.Nombre + ',' + D.Apellido) AS Dueño, M.Nombre AS Mascota, FC.Descripcion AS Consulta, C.Costo FROM Cobros C
INNER JOIN FichaConsulta FC ON C.IDFicha = FC.IDFicha
INNER JOIN Turnos T ON FC.IDTurno = T.IDTurno
INNER JOIN Mascotas M ON M.IDMascota = T.IDMascota
INNER JOIN Dueños D ON M.DniDueño = D.Dni
WHERE C.Activo = 1
GO

---------------------------- VISTA DE COBROS MENSUALES ---------------------------
CREATE OR ALTER VIEW VW_CobrosMensuales AS
SELECT FORMAT(T.FechaHora, 'yyyy-MM') AS Mes, SUM(C.Costo) AS TotalMensual
FROM Cobros C
INNER JOIN FichaConsulta FC ON C.IDFicha = FC.IDFicha
INNER JOIN Turnos T ON FC.IDTurno = T.IDTurno
WHERE C.Activo = 1
GROUP BY FORMAT(T.FechaHora, 'yyyy-MM');







