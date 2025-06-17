
-- ===============================================================================
-- ===============================================================================
-- =======================[   T R I G G E R S   ]=================================
-- ===============================================================================
-- ===============================================================================

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
---------------------------------------------------------------------------------------------------------------
------------------------- Eliminar Usuario de forma logica, SI NO PERTENECE A NADIE ---------------------------
CREATE OR ALTER  TRIGGER tg_EliminarUsuarioLogico
On Usuarios
INSTEAD OF DELETE
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION

        DECLARE @User VARCHAR(25)
        SELECT @User = Usuario FROM deleted


        IF ((SELECT COUNT(*) FROM Veterinarios WHERE Usuario = @User AND Activo = 1) > 0 OR (SELECT COUNT(*) FROM Recepcionistas WHERE Usuario = @User AND Activo = 1) > 0)
        BEGIN
            RAISERROR('EXISTE UN EMPLEADO ACTIVO CON ESE USUARIO', 16, 1)
            ROLLBACK TRANSACTION
            RETURN
        END

        UPDATE Usuarios
        SET Activo = 0
        WHERE Usuario = @User

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE()
    END CATCH
END
GO
------------------------------------------------------------------------------------
----------- ELIMINAR DUEÑO DE FORMA LOGICA, SI NO TIENE MASCOTA  ------------------------
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
------------------------------------------------------------------------
----------------------ELIMINAR UN TURNO DE FORMA LOGICA---------------
CREATE OR ALTER TRIGGER tg_EliminarTurnoLogico
ON Turnos
INSTEAD OF DELETE
AS 
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			-- Verifica si hay al menos un turno en estado diferente de 'PENDIENTE'
			DECLARE @idTurno int
			SELECT @idTurno = IDTurno FROM deleted
		
			IF (SELECT Estado FROM Turnos WHERE IDTurno = @idTurno) != 'PENDIENTE'
			BEGIN
				RAISERROR('El turno se encuentra en un estado de REALIZADO o COBRADO.', 16, 1);
				RETURN;
			END

			UPDATE Turnos
			SET Activo = 0
			WHERE IDTurno IN (SELECT IDTurno FROM deleted);
			PRINT 'TURNO ELIMINADO CON EXITO'

		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		PRINT ERROR_MESSAGE()
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH
END
GO
-----------------------------------------------------------------------------------
------------------ USAR TURNO ELIMINADO CON OTRA MASCOTA --------------------------
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
----------------------------------------------------------------------------------------
------------------------- Eliminar Recepcionista de forma logica -----------------------
CREATE OR ALTER  TRIGGER tg_EliminarRecepcionistaLogico
On Recepcionistas
INSTEAD OF DELETE
AS
BEGIN
	BEGIN TRY
		UPDATE Recepcionistas
		SET Activo = 0
		WHERE Legajo = (SELECT Legajo From deleted)
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

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
------------------------- Eliminar Veterinario de forma logica -----------------------
CREATE OR ALTER  TRIGGER tg_EliminarVeterinarioLogico
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
------------------------- Eliminar FichaConsulta de forma logica -----------------------
CREATE OR ALTER  TRIGGER tg_EliminarFichaConsultaLogico
On FichaConsulta
INSTEAD OF DELETE
AS
BEGIN	
	UPDATE FichaConsulta
	SET Activo = 0
	WHERE IDFicha = (SELECT IDFicha From deleted)

	UPDATE Cobros
    	SET Activo = 0
    	WHERE IDFicha IN (SELECT IDFicha FROM DELETED);
END
GO
--------------------------------------------------------------------------------------
-------------------CAMBIAR EL ESTADO DEL TURNO SI SE REALIZA EL COBRO (COBROS)-------
CREATE OR ALTER TRIGGER tg_cambiarEstadoTurno_Cobros
ON Cobros
AFTER INSERT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
		 DECLARE @idFicha int
		 DECLARE @idTurno int
		 Select @idFicha = IDFicha FROM INSERTED 
		 Select @idTurno = IDTurno FROM FichaConsulta WHERE IDFicha = @idFicha
	
		UPDATE Turnos SET	Estado = 'COBRADO' WHERE IDTurno = @idTurno
	
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
	END CATCH
END
GO
