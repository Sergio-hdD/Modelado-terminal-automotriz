delimiter $$
create procedure iniciarFabricacionDelVehiculoConCursor(OUT nResultado INT, OUT cMensaje VARCHAR(500), in nro_chasis_imput varchar(45)) -- en vehiculo x estacion   estacion 1 de en la linea de su modelo
	begin
        declare id_modeloAux INT DEFAULT 0;
        declare chasisOcupante varchar(45) default null;
        declare chasis_aux varchar(45)default null;  
        declare fecha_hora_entrada_aux varchar(45)default null;  
        declare fecha_hora_salida_aux varchar(45)default null;  
        declare done int default 0;
		declare bandera bool default true; 
        DECLARE curAgregarAEstacion1
              CURSOR FOR
            SELECT id_vehiculo,fecha_hora_entrada,fecha_hora_salida from vehiculo_x_estacion WHERE id_estacion=1; -- declaramos u
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1; 
		select id_modelo from vehiculo where nro_chasis = nro_chasis_imput into id_modeloAux;
        OPEN curAgregarAEstacion1; -- abrimos el cursor para recorrerlo
        bucle:LOOP -- inicio un loop con nombre "bucle" para recorrer el cursor abierto
				 fetch curAgregarAEstacion1 into chasis_aux,fecha_hora_entrada_aux,fecha_hora_salida_aux; -- los datos de las columnas de cada registro los guardo en distintas variables
                 if fecha_hora_salida_aux is null then -- si encuentro uno que tenga fecha de salida en null (es decir está ocupando la estación 1)
					 if exists (select nro_chasis from vehiculo where  id_modelo=id_modeloAux and chasis_aux=nro_chasis) then -- me fijo es del mismo modelo del que recibí por parametros (el que quiero agregar a la estación 1, ya que solo lo puedo agregar en una estación de la linea de montaje del mismo modelo) 
					  set chasisOcupante = chasis_aux;  -- guardo el nr. de chasis del que esté  en la estación 1, tenga la fecha de salida en null y sea del mismo modelo del que recibí por parametros
					 end if;
                 end if;
        	IF done = 1 THEN
            LEAVE bucle;
			end if;
            
        end loop bucle;
        CLOSE curAgregarAEstacion1;
         
        if id_modeloAux>0 then -- si el nro de chasis fue asignado a algún modelo
			if chasisOcupante is not null then -- si hay uno en la estación 1 que tenga la fecha de salida en null y sea del mismo modelo del que recibí por parametros
				select -1 INTO nResultado;	
				select CONCAT('La estacion esta ocupada por el vehículo ',chasisOcupante) INTO cMensaje;
			else -- Si está vacia la estación 1 de la linea de montaje que corresponde al modelo del chasis que recibí por parametros
				update vehiculo_x_estacion set fecha_hora_entrada = current_time(), id_estacion = 1 
				where id_estacion = 0 and id_vehiculo = nro_chasis_imput;-- ingreso el vehiculo a le estación 1
				select 0 INTO nResultado;	
				select ' ' INTO cMensaje;
			end if;
        else -- se ingresó nro de chasis que NO asignado a algún modelo (es un dato erroneo)
			select -1 INTO nResultado;	
			select CONCAT('El nro. de chasis ',nro_chasis_imput,' no está asignado a ningún vehículo') INTO cMensaje;
        end if;
	end $$
delimiter ;

select * from vehiculo;

-- ***** PRUEBAS *****
-- ***************************************************************************
set @cResultado =0;        
call iniciarFabricacionDelVehiculoConCursor(@cResultado,@cMensaje,'3EPDW57A2G2855233');
select @cResultado, @cMensaje;-- con los datos originalmente cargados  esto en cResultado "-1" y en cMensaje "La estacion esta ocupada por el vehiculo 3CGSG97W6G6262393" 

select * from vehiculo_x_estacion where id_estacion = 1 and id_vehiculo ='3CGSG97W6G6262393';-- este es el vehiculo que encuentra en la estación 1 de linea_de_montaje, que le corresponde por modelo, al vehículo '3EPDW57A2G2855233' que pasé como parametro en el "call iniciarFabricacionDelVehiculo(...);"
-- ***************************************************************************
-- para que anda el cResultado "0" ejecuto este código
 update vehiculo_x_estacion set fecha_hora_salida = current_time() 
 where id_estacion = 1 and id_vehiculo ='3CGSG97W6G6262393';
 
set @cResultado =0;        
call iniciarFabricacionDelVehiculoConCursor(@cResultado,@cMensaje,'3EPDW57A2G2855233');
select @cResultado, @cMensaje;-- ahora en cResultado "0" y en cMensaje ' '

 select * from vehiculo_x_estacion where id_estacion = 1 and id_vehiculo ='3EPDW57A2G2855233';-- El vehículo '3EPDW57A2G2855233' que pasé como parametro en el "call iniciarFabricacionDelVehiculo(...) con fecha_hora_entrada de momento del update y fecha_hora_salida en null
-- ***************************************************************************
-- para dejar todo en estado inicial (dos pasos)
-- 1) saco el vehículo (3EPDW57A2G2855233) que ingresé en la estación 1
 update vehiculo_x_estacion set fecha_hora_entrada = null, id_estacion=0
 where id_estacion = 1 and id_vehiculo ='3EPDW57A2G2855233';
-- 2) regreso el vehículo (3CGSG97W6G6262393) que saqué de la estación 1 
  update vehiculo_x_estacion set fecha_hora_salida = null 
 where id_estacion = 1 and id_vehiculo ='3CGSG97W6G6262393';
 -- ***************************************************************************
 -- si se ingresa un chasis que no fue asingado a ningún vehículo
 set @cResultado =0;        
call iniciarFabricacionDelVehiculoConCursor(@cResultado,@cMensaje,'x.x_x-x');
select @cResultado, @cMensaje;-- ahora en cResultado "-1" y en cMensaje "El nro. de chasis x.x_x-x no está asignado a ningún vehículo"


