------------------------------------Modelos de parcial SQL---------------------------------------------------
/*1. Se solicita estadística por Año y familia, para ello se deberá mostrar.
Año, Código de familia, Detalle de familia, cantidad de facturas, cantidad
de productos con COmposición vendidOs, monto total vendido.
 Solo se deberán considerar las familias que tengan al menos un producto con
composición y que se hayan vendido conjuntamente (en la misma factura)
con otra familia distinta.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones
definidas por el usuario para este punto,*/
select distinct comp_producto from Composicion

select 
YEAR(fac1.fact_fecha) AS [ANIO],
fa.fami_id,
fa.fami_detalle,
COUNT(DISTINCT fac1.fact_numero + fac1.fact_sucursal + fac1.fact_tipo) AS [CANTIDAD DE FACTURAS],
(
        SELECT COUNT(DISTINCT c1.comp_producto) 
        FROM Composicion c1
        INNER JOIN Item_Factura i1 ON i1.item_producto = c1.comp_producto
        INNER JOIN Factura f1 ON f1.fact_numero + f1.fact_sucursal + f1.fact_tipo = i1.item_numero + i1.item_sucursal + i1.item_tipo
        INNER JOIN Producto p1 ON p1.prod_codigo = i1.item_producto
        WHERE p1.prod_familia = fa.fami_id 
          AND YEAR(f1.fact_fecha) = YEAR(fac1.fact_fecha)
          AND f1.fact_numero + f1.fact_sucursal + f1.fact_tipo IN (
              SELECT i_a.item_numero + i_a.item_sucursal + i_a.item_tipo
              FROM Item_Factura i_a
              INNER JOIN Producto p_a ON i_a.item_producto = p_a.prod_codigo
              INNER JOIN Item_Factura i_b ON i_a.item_numero + i_a.item_sucursal + i_a.item_tipo = i_b.item_numero + i_b.item_sucursal + i_b.item_tipo
              INNER JOIN Producto p_b ON i_b.item_producto = p_b.prod_codigo
              WHERE p_a.prod_familia = fa.fami_id AND p_b.prod_familia <> fa.fami_id
          )
    ) AS [CANTIDAD DE PROD COMPOSICION VENDIDOS],
	 SUM(item1.item_cantidad * item1.item_precio) AS [MONTO TOTAL]
from Producto p1
inner join Item_Factura item1 on item1.item_producto = p1.prod_codigo
inner join Factura fac1 on fac1.fact_numero = item1.item_numero and fac1.fact_sucursal = item1.item_sucursal and fac1.fact_tipo = item1.item_tipo
inner join Familia fa on fa.fami_id = p1.prod_familia
where
 -- CORREGIDO: Filtro que evalúa si LA FACTURA ACTUAL contenía otra familia distinta
    fac1.fact_numero + fac1.fact_sucursal + fac1.fact_tipo IN (
        SELECT i2.item_numero + i2.item_sucursal + i2.item_tipo
        FROM Item_Factura i2
        INNER JOIN Producto p2 ON i2.item_producto = p2.prod_codigo
        -- i es la tabla del FROM principal. Acá obligamos a que comparen la misma factura
        WHERE i2.item_numero + i2.item_sucursal + i2.item_tipo = fac1.fact_numero + fac1.fact_sucursal + fac1.fact_tipo
          AND p2.prod_familia <> p1.prod_familia
    )
    -- Y que la familia tenga históricamente al menos un producto con composición
    AND fa.fami_id IN (
        SELECT p3.prod_familia 
        FROM Producto p3
        INNER JOIN Composicion c3 ON p3.prod_codigo = c3.comp_producto
    )


/*2 Se pide que realice un reporte generado por una sola query que de cortes de informacion por periodos
(anual,semestral y bimestral). Un corte por el año, un corte por el semestre el año y un corte por bimestre el año. 
En el corte por año mostrar las ventas totales realizadas por año, la cantidad de rubros distintos comprados por año, 
la cantidad de productos con composicion distintos comporados por año y la cantidad de clientes que compraron por año.
Luego, en la informacion del semestre mostrar la misma informacion, es decir, las ventas totales por semestre, cantidad de rubros 
por semestre, etc. y la misma logica por bimestre. El orden tiene que ser cronologico.

*/

select 
--year(f1.fact_fecha) as periodo,
CONCAT(YEAR(f1.fact_fecha), '') AS 'Periodo',
sum(f1.fact_total) as venta_total,
(select count(distinct p2.prod_rubro) from Producto p2 
inner join Item_Factura i2 on i2.item_producto = p2.prod_codigo 
inner join Factura f2 on i2.item_numero + i2.item_sucursal + i2.item_tipo = f2.fact_numero + f2.fact_sucursal + f2.fact_tipo
where year(f2.fact_fecha) = year(f1.fact_fecha)) as cantidad_rubros_diferentes,
(
	select count(distinct c1.comp_producto) from Composicion c1 inner join Producto p3 on p3.prod_codigo = c1.comp_producto
	inner join Item_Factura i3 on i3.item_producto = p3.prod_codigo
	inner join Factura f3 on f3.fact_numero = i3.item_numero and f3.fact_sucursal = i3.item_sucursal and f3.fact_tipo = i3.item_tipo
	where year(f3.fact_fecha) = year(f1.fact_fecha) 
) cant_prod_compuestos,
count(distinct f1.fact_cliente) clientes
from Factura f1
group by year(f1.fact_fecha)

union all

select 
CONCAT(YEAR(f1.fact_fecha), ' - Semestre ', (CASE WHEN MONTH(f1.fact_fecha) <= 6 THEN 1 ELSE 2 END)) AS 'Periodo',
sum(f1.fact_total) as venta_total,
(select count(distinct p2.prod_rubro) from Producto p2 
inner join Item_Factura i2 on i2.item_producto = p2.prod_codigo 
inner join Factura f2 on i2.item_numero + i2.item_sucursal + i2.item_tipo = f2.fact_numero + f2.fact_sucursal + f2.fact_tipo
where year(f2.fact_fecha) = year(f1.fact_fecha) and  
(CASE WHEN MONTH(f1.fact_fecha) <= 6 THEN 1 ELSE 2 END) =  (CASE WHEN MONTH(f2.fact_fecha) <= 6 THEN 1 ELSE 2 END) ) as cantidad_rubros_diferentes,
(
	select count(distinct c1.comp_producto) from Composicion c1 inner join Producto p3 on p3.prod_codigo = c1.comp_producto
	inner join Item_Factura i3 on i3.item_producto = p3.prod_codigo
	inner join Factura f3 on f3.fact_numero = i3.item_numero and f3.fact_sucursal = i3.item_sucursal and f3.fact_tipo = i3.item_tipo
	where year(f3.fact_fecha) = year(f1.fact_fecha)  
	and (CASE WHEN MONTH(f1.fact_fecha) <= 6 THEN 1 ELSE 2 END) =  (CASE WHEN MONTH(f3.fact_fecha) <= 6 THEN 1 ELSE 2 END)
) cant_prod_compuestos,
count(distinct f1.fact_cliente) clientes
from Factura f1
group by year(f1.fact_fecha), (CASE WHEN MONTH(f1.fact_fecha) <= 6 THEN 1 ELSE 2 END)

union all

SELECT 
    CONCAT(YEAR(f1.fact_fecha), ' - Bimestre ', (FLOOR((MONTH(f1.fact_fecha)-1)/2) + 1)) AS 'Periodo', 
    SUM(f1.fact_total) AS 'Ventas totales',
    
    (SELECT COUNT(DISTINCT prod_rubro) 
     FROM Item_Factura 
     JOIN Producto ON prod_codigo = item_producto 
     JOIN Factura f2 ON f2.fact_numero = item_numero AND f2.fact_sucursal = item_sucursal AND f2.fact_tipo = item_tipo 
     WHERE YEAR(F2.fact_fecha) = YEAR(f1.fact_fecha) 
       AND (FLOOR((MONTH(f2.fact_fecha)-1)/2) + 1) = (FLOOR((MONTH(f1.fact_fecha)-1)/2) + 1)) AS 'Cant rubros',
    
    (SELECT COUNT(DISTINCT prod_codigo) 
     FROM Item_Factura 
     JOIN Producto ON prod_codigo = item_producto 
     JOIN Composicion ON comp_producto = prod_codigo 
     JOIN Factura f2 ON f2.fact_numero = item_numero AND f2.fact_sucursal = item_sucursal AND f2.fact_tipo = item_tipo 
     WHERE YEAR(F2.fact_fecha) = YEAR(f1.fact_fecha) 
       AND (FLOOR((MONTH(f2.fact_fecha)-1)/2) + 1) = (FLOOR((MONTH(f1.fact_fecha)-1)/2) + 1)) AS 'Cant productos compuestos',
    
    COUNT(DISTINCT f1.fact_cliente) AS 'Clientes'
FROM Factura f1 
GROUP BY YEAR(f1.fact_fecha), (FLOOR((MONTH(f1.fact_fecha)-1)/2) + 1)
order by 1


/*3 Armar una consulta Sql que retorne: DONE

	Razón social del cliente
	Límite de crédito del cliente
	Producto más comprado en la historia (en unidades)     -- Yo interpreto que es el producto mas comprado en la historia del cliente

	Solamente deberá mostrar aquellos clientes que tuvieron mayor cantidad de ventas en el 2012 que
    en el 2011 en cantidades y cuyos montos de ventas en dichos años sean un 30 % mayor el 2012 con
    respecto al 2011. 

	El resultado deberá ser ordenado por código de cliente ascendente

NOTA: No se permite el uso de sub-selects en el FROM.
*/

select clie.clie_razon_social,
clie.clie_limite_credito,
(select top 1 i2.item_producto from Item_Factura i2 
inner join Factura f2 
on f2.fact_numero = i2.item_numero AND f2.fact_sucursal = i2.item_sucursal AND f2.fact_tipo = i2.item_tipo
where f2.fact_cliente = clie.clie_codigo
group by i2.item_producto
order by SUM(i2.item_cantidad) desc)
from Cliente clie
inner join Factura f1 on f1.fact_cliente = clie_codigo
inner join Item_Factura i1 on f1.fact_numero = i1.item_numero AND f1.fact_sucursal = i1.item_sucursal AND f1.fact_tipo = i1.item_tipo 
group by clie.clie_razon_social,
clie.clie_limite_credito,
clie.clie_codigo
having
    -- 2. COMPARACIÓN DE CANTIDADES (Mayor cantidad de unidades en 2012 que en 2011)
    SUM(CASE WHEN YEAR(f1.fact_fecha) = 2012 THEN i1.item_cantidad ELSE 0 END) > 
    SUM(CASE WHEN YEAR(f1.fact_fecha) = 2011 THEN i1.item_cantidad ELSE 0 END)
	and

	-- 1. COMPARACIÓN DE MONTOS (2012 un 30% mayor que 2011)
    SUM(CASE WHEN YEAR(f1.fact_fecha) = 2012 THEN i1.item_cantidad * i1.item_precio ELSE 0 END) > 
    SUM(CASE WHEN YEAR(f1.fact_fecha) = 2011 THEN i1.item_cantidad * i1.item_precio ELSE 0 END) * 1.3
order by clie.clie_codigo asc 


/* todavia no lo compare con nadie
4. Realizar una consulta SQL que permita saber si un cliente compro un producto en todos los meses del 2012.

Además, mostrar para el 2012: 
1. El cliente
2. La razón social del cliente
3. El producto comprado
4. El nombre del producto
5. Cantidad de productos distintos comprados por el cliente.
6. Cantidad de productos con composición comprados por el cliente.

El resultado deberá ser ordenado poniendo primero aquellos clientes que compraron más de 10 productos distintos en el 2012. 
*/

select 
clie.clie_codigo,
clie.clie_razon_social,
p1.prod_codigo,
p1.prod_detalle,
(select COUNT(distinct i2.item_producto) from Item_Factura i2 
inner join Factura f2 on f2.fact_numero = i2.item_numero AND f2.fact_sucursal = i2.item_sucursal AND f2.fact_tipo = i2.item_tipo
where f2.fact_cliente = clie_codigo and year(f2.fact_fecha) = 2012),
(
        SELECT COUNT(DISTINCT c.comp_producto)
        FROM Item_Factura i3
        INNER JOIN Factura f3 ON f3.fact_numero + f3.fact_sucursal + f3.fact_tipo = i3.item_numero + i3.item_sucursal + i3.item_tipo
        INNER JOIN Composicion c ON i3.item_producto = c.comp_producto
        WHERE f3.fact_cliente = clie.clie_codigo AND YEAR(f3.fact_fecha) = 2012
    ) AS [Cant Prod Compuestos]
from Cliente clie 
inner join Factura f1 on f1.fact_cliente = clie.clie_codigo
inner join Item_Factura i1 on f1.fact_numero = i1.item_numero AND f1.fact_sucursal = i1.item_sucursal AND f1.fact_tipo = i1.item_tipo 
inner join Producto p1 on p1.prod_codigo = i1.item_producto
where year(f1.fact_fecha) = 2012
group by clie.clie_codigo,
clie.clie_razon_social,
p1.prod_codigo,
p1.prod_detalle
HAVING 
    -- LA CLAVE: Contar meses distintos en 2012. Si da 12, se compró todos los meses.
    COUNT(DISTINCT MONTH(f1.fact_fecha)) = 12
ORDER BY 
    -- Criterio de ordenamiento pedido por el enunciado
    CASE 
        WHEN (
            SELECT COUNT(DISTINCT i_o.item_producto)
            FROM Item_Factura i_o
            INNER JOIN Factura f_o ON f_o.fact_numero + f_o.fact_sucursal + f_o.fact_tipo = i_o.item_numero + i_o.item_sucursal + i_o.item_tipo
            WHERE f_o.fact_cliente = clie.clie_codigo AND YEAR(f_o.fact_fecha) = 2012
        ) > 10 THEN 1 
        ELSE 2 
    END ASC,
    clie.clie_codigo ASC;


----------------------------------------------Parciales no resueltos--------------------------------
/* Realizar una consulta SQL que permita saber los clientes que

compraron por encima del promedio de compras (fact_total) de todos
los clientes del 2012.

De estos clientes mostrar para el 2012:
1.El código del cliente
2.La razón social del cliente
3.Código de producto que en cantidades más compro.
4,El nombre del producto del punto 3.
5,Cantidad de productos distintos comprados por el cliente,
6.Cantidad de productos con composición comprados por el cliente,

EI resultado deberá ser ordenado poniendo primero aquellos clientes
que compraron más de entre 5 y 10 productos distintos en el 2012 */


SELECT
	c.clie_codigo,
	c.clie_razon_social,

	ISNULL(
	(
		SELECT TOP 1 i3.item_producto
		FROM Item_Factura i3
			INNER JOIN Factura f3 ON
			i3.item_tipo = f3.fact_tipo AND i3.item_sucursal = f3.fact_sucursal AND i3.item_numero = f3.fact_numero
		WHERE YEAR(f3.fact_fecha) = 2012 AND f3.fact_cliente = c.clie_codigo
		GROUP BY i3.item_producto
		ORDER BY SUM(i3.item_cantidad) DESC
	),'NO HAY PRODUCTO') AS codigo_producto_mas_comprado,


	ISNULL((
	SELECT TOP 1 p5.prod_detalle
	FROM Item_Factura i5
	INNER JOIN Factura f5 ON
		i5.item_tipo = f5.fact_tipo
		AND i5.item_sucursal = f5.fact_sucursal
		AND i5.item_numero = f5.fact_numero
	INNER JOIN Producto p5 ON
		i5.item_producto = p5.prod_codigo
	WHERE
		YEAR(f5.fact_fecha) = 2012
		AND f5.fact_cliente = c.clie_codigo
	GROUP BY
		i5.item_producto,
		p5.prod_detalle
	ORDER BY
		SUM(i5.item_cantidad) DESC),
	'NO HAY PRODUCTO') AS detalle_producto_mas_comprado,

	COUNT(DISTINCT i.item_producto) AS productos_distintos,

	COUNT(DISTINCT C2.comp_producto) AS productos_compuestos

FROM Cliente c
INNER JOIN Factura f 
	ON c.clie_codigo = f.fact_cliente
INNER JOIN Item_Factura i 
	ON f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero
LEFT JOIN Composicion C2 ON
    C2.comp_producto = I.item_producto
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY c.clie_codigo, c.clie_razon_social
HAVING
	(
	SELECT SUM(f.fact_total)
	FROM Factura f
	WHERE f.fact_cliente = c.clie_codigo
		AND YEAR(f.fact_fecha) = 2012) > 
		(
			SELECT AVG(f2.fact_total)
			FROM Factura f2
			WHERE YEAR(f2.fact_fecha) = 2012 
		)
ORDER BY c.clie_codigo
	--CASE
	--	WHEN COUNT(DISTINCT i.item_producto) BETWEEN 5 AND 10 THEN 1
	--	ELSE 2
	--END ASC

/*:DONE

I, Realizar una consulta SQL que permita saber 

	los clientes que compraron todos los rubros disponibles del sistema en el 2012.

De estos clientes mostrar, siempre para el 2012: 

	1.El código del cliente
	2.Código de producto que en cantidades más compro.
	3.El nombre del producto del punto 2.

	4,Cantidad de productos distintos comprados por el cliente.

	5.Cantidad de productos con composición comprados por el cliente.

El resultado deberá ser ordenado por razón social del cliente
alfabéticamente primero y luego, los clientes que compraron entre un
20 % y 30% del total facturado en el 2012 primero, luego, los restantes,
*/


SELECT 
	CL.clie_codigo,
	(
		select top 1 I1.item_producto
		from Factura F1
			inner join Item_Factura I1
				on F1.fact_tipo+F1.fact_sucursal+F1.fact_numero=I1.item_tipo+I1.item_sucursal+I1.item_numero
			where F1.fact_cliente = CL.clie_codigo AND YEAR(F1.fact_fecha) = 2012
		GROUP BY I1.item_producto
		ORDER BY SUM(I1.item_cantidad) DESC
	) AS CODIGO_PRODUCTO_MAS_COMPRADO,
	(
		select top 1 P2.prod_detalle
		from Factura F2
			inner join Item_Factura I2
				on F2.fact_tipo+F2.fact_sucursal+F2.fact_numero=I2.item_tipo+I2.item_sucursal+I2.item_numero
			inner join Producto P2 
				on P2.prod_codigo = I2.item_producto
			where F2.fact_cliente = CL.clie_codigo AND YEAR(F2.fact_fecha) = 2012
			
		GROUP BY I2.item_producto,P2.prod_detalle
		ORDER BY SUM(I2.item_cantidad) DESC
	) AS DETALLE_PRODUCTO_MAS_COMPRADO,
	COUNT(DISTINCT I.item_producto) AS [Cantidad de productos distintos comprados por el cliente],
	COUNT(DISTINCT CC.comp_producto)  AS [5.Cantidad de productos con composición comprados por el cliente.]

FROM Cliente CL
	INNER JOIN Factura F 
		ON F.fact_cliente = CL.clie_codigo
	INNER JOIN Item_Factura I
		ON F.fact_tipo+F.fact_sucursal+F.fact_numero=I.item_tipo+I.item_sucursal+I.item_numero
	INNER JOIN Producto PD
		ON PD.prod_codigo = I.item_producto
	LEFT JOIN Composicion CC 
		ON CC.comp_producto = I.item_producto
WHERE YEAR(F.fact_fecha) = 2012
GROUP BY CL.clie_codigo, CL.clie_razon_social
--HAVING COUNT (DISTINCT PD.prod_rubro) = ( SELECT COUNT( R.rubr_id) FROM Rubro R)  creo q esto ta bien pero no hay productos en db para testear
ORDER BY CL.clie_razon_social ASC , 
	( case when sum(F.fact_total)
				 BETWEEN ((SELECT SUM(FT.fact_total) 
						FROM Factura FT
						WHERE YEAR(FT.fact_fecha) = 2012) * 0.2) and ((SELECT SUM(FT.fact_total) 
						FROM Factura FT
						WHERE YEAR(FT.fact_fecha) = 2012) * 0.3)   then 1 
						ELSE 0
	end) ASC

/* pensar en un big mac : buger papa coca
Realizar una consulta SQL que muestre aquellos productos que 

	  tengan 3 componentes a nivel producto y 
	  cuyos componentes tengan 2 rubros distintos.
 
De estos productos mostrar:
	 i.El código de producto.
	 ii.El nombre del producto.
	 iii.La cantidad de veces que fueron vendidos sus componentes en el 2012.
	 iv.Monto total vendido del producto.

El resultado ser ordenado por cantidad de facturas del 2012 en las cuales se vendieron los componentes.

Nota: No se permiten select en el from, es decir, select from (select as T....
*/

SELECT
	P.prod_codigo as [Codigo de Producto],
	P.prod_detalle as [Nombre de Producto],
	ISNULL(
		(
			SELECT count(F.fact_numero + F.fact_sucursal + F.fact_tipo ) 
			FROM Item_Factura IT2 
				INNER JOIN Factura F 
					ON F.fact_numero + F.fact_sucursal + F.fact_tipo = IT2.item_numero + IT2.item_sucursal + IT2.item_tipo 
				INNER JOIN Composicion C3 
					ON C3.comp_producto = P.prod_codigo
			WHERE IT2.item_producto = C3.comp_componente AND YEAR(F.fact_fecha) = 2012
			) ,0) as [Cantidad de Componentes vendida en 2012],

	ISNULL((
		SELECT SUM(IT.item_precio + IT.item_cantidad)  
		FROM Item_Factura IT 
		WHERE IT.item_producto = P.prod_codigo
		),0 ) AS [Monto Vendido Producto]

FROM Producto P 
    INNER JOIN Composicion C 
		ON C.comp_producto = P.prod_codigo

GROUP BY P.prod_codigo,P.prod_detalle

HAVING (--cuyos componentes tengan 2 rubros distintos.
			SELECT COUNT(DISTINCT P6.prod_rubro)
			FROM Producto P6
			INNER JOIN Composicion C6 ON P6.prod_codigo = C6.comp_componente
			WHERE C6.comp_producto = P.prod_codigo
	   ) > 1
	   and
	    (
		SELECT COUNT(DISTINCT C2.comp_componente) 
		FROM Composicion C2 
		WHERE C2.comp_producto = P.prod_codigo
	   ) > 1 -- ACA VA UN 2 PORQUE EN LA BASE DE DATOS NO HAY NINGUNO DE 3 COMPONENTES.

ORDER BY (
			select count( f8.fact_numero + f8.fact_sucursal + f8.fact_tipo ) from Factura f8
				inner join Item_Factura i8
					ON f8.fact_numero + f8.fact_sucursal + f8.fact_tipo = i8.item_numero + i8.item_sucursal + i8.item_tipo
				inner join Composicion C8 
					ON C8.comp_producto = P.prod_codigo
				where i8.item_producto = C8.comp_componente 

		 ) DESC

--El resultado ser ordenado por cantidad de facturas del 2012 en las cuales se vendieron los componentes. 

/*
I.Realizar una consulta SQL que retorne para 

 todas las zonas que tengan 3 (tres) o más depósitos.

	 Detalle Zona
	 Cantidad de Depósitos x Zona
? Cantidad de Productos distintos compuestos en sus depósitos
? Producto mas vendido en el año 2012 que tonga stock en al menos uno de sus depósitos.
?	Mejor encargado perteneciente a esa zona (El que mas vendió en la historia).

El resultado deberá ser ordenado por monto total vendido del encargado DESC.

zona--> deposito --> Stock
*/


/*
1. Realizar una consulta SOL que retorne para los 10 clientes que más
compraron en el 2012 y que fueron atendldos por más de 3 vendedores
distintos:

 Apellido y Nombro del Cliento.
 Cantidad de Productos distmtos comprados en el 2012,
 Cantidad de unidades compradas dentro del pomer semestre del 2012.

•El resultado deberá mostrar ordenado ta cantidad de ventas descendente
	del 2012 de cada cliente, en caso de igualdad de ventasi ordenar porcódigo de cliente.

NOTA: No se permite el uso de sub-setects en el FROM ni funciones definidas por el usuario para este punto,
*/

SELECT TOP 10 
C.clie_razon_social as [Cliente-Razon Social],
COUNT(DISTINCT IT.item_producto) as [Unidades compradas Semestral],
(
SELECT
SUM(IT2.item_cantidad)
FROM Factura F2
	INNER JOIN Item_Factura IT2 ON
		F2.fact_tipo+F2.fact_numero+F2.fact_sucursal = IT2.item_tipo+IT2.item_numero+IT2.item_sucursal
	WHERE F2.fact_cliente = F.fact_cliente AND YEAR(F2.fact_fecha) = 2012 AND MONTH(F2.fact_fecha) <=6
) as [Producos del primer semestre]
FROM Factura F
	INNER JOIN Cliente C ON
		C.clie_codigo = F.fact_cliente
	INNER JOIN Item_Factura IT ON
		F.fact_tipo+F.fact_numero+F.fact_sucursal = IT.item_tipo+IT.item_numero+IT.item_sucursal
	WHERE YEAR(F.fact_fecha) = 2012
	GROUP BY F.fact_cliente,C.clie_razon_social,C.clie_codigo
	--HAVING COUNT(DISTINCT F.fact_vendedor) > 3
	ORDER BY COUNT(F.fact_cliente)DESC ,C.clie_codigo DESC

SELECT 
	Z.zona_codigo,
	Z.zona_detalle,
	COUNT(DISTINCT D.depo_codigo) AS Depositos_X_Zona
	,
	(
		select count(distinct C1.comp_producto) 
			from Composicion C1 
				INNER JOIN STOCK S1 
					ON S1.stoc_producto = C1.comp_producto
				INNER JOIN DEPOSITO D1 
					ON D1.depo_codigo = S1.stoc_deposito
				INNER JOIN ZONA Z1
					ON D1.depo_zona = Z1.zona_codigo
			WHERE  Z1.zona_codigo = Z.zona_codigo
			--GROUP BY C1.comp_producto PORQ NO VA ESTO? A BORDA
	) AS CANT_PRODUCTOS_COMPOSICION_DISTINTOS_EN_DEPOSITOS,
	(	-- PORQUE ME DA DISTINTO AL DE SANTI?
		SELECT TOP 1 I2.item_producto

		FROM Factura F2
			INNER JOIN Item_Factura I2 
				ON F2.fact_tipo+F2.fact_sucursal+F2.fact_numero = I2.item_tipo+I2.item_sucursal+I2.item_numero
			INNER JOIN Producto P2 
				ON I2.item_producto = P2.prod_codigo
			INNER JOIN STOCK S2
				ON S2.stoc_producto = P2.prod_codigo
			INNER JOIN DEPOSITO D2 
				ON D2.depo_codigo = S2.stoc_deposito
		WHERE D2.depo_zona = Z.zona_codigo AND YEAR(F2.fact_fecha) = 2012
		GROUP BY I2.item_producto
		ORDER BY SUM(I2.item_cantidad) DESC
	) AS PRODUCTO_MAS_VENDIDO_2012,
	(
		SELECT TOP 1 E3.empl_codigo 
		FROM Empleado E3
			INNER JOIN Factura F3 
				ON F3.fact_vendedor = E3.empl_codigo
		WHERE E3.empl_codigo  IN (
										SELECT D3.depo_encargado FROM DEPOSITO D3 
										WHERE D3.depo_zona = Z.zona_codigo
								)
		GROUP BY E3.empl_codigo,F3.fact_vendedor 
		ORDER BY SUM(F3.fact_total) DESC
			
	) AS MEJOR_VENDEDOR,
	(
		SELECT TOP 1 SUM(F3.fact_total) 
		FROM Empleado E3
			INNER JOIN Factura F3 
				ON F3.fact_vendedor = E3.empl_codigo
		WHERE E3.empl_codigo  IN (
										SELECT D3.depo_encargado FROM DEPOSITO D3 
										WHERE D3.depo_zona = Z.zona_codigo
								)
		GROUP BY E3.empl_codigo,F3.fact_vendedor 
		ORDER BY SUM(F3.fact_total) DESC
			
	) AS TOTAL_MEJOR_VENDEDOR

FROM DEPOSITO D 
	INNER JOIN Zona Z
		ON Z.zona_codigo = D.depo_zona
GROUP BY Z.zona_codigo,Z.zona_detalle
HAVING COUNT(DISTINCT D.depo_codigo) >= 3

ORDER BY  (
(
		SELECT TOP 1 SUM(F3.fact_total) 
		FROM Empleado E3
			INNER JOIN Factura F3 
				ON F3.fact_vendedor = E3.empl_codigo
		WHERE E3.empl_codigo  IN (
										SELECT D3.depo_encargado FROM DEPOSITO D3 
										WHERE D3.depo_zona = Z.zona_codigo
								)
		GROUP BY E3.empl_codigo,F3.fact_vendedor 
		ORDER BY SUM(F3.fact_total) DESC
			
	) 
) DESC

/*
--------------------------- PARCIAL 28/07/2023 ---------------------------
1) 
Realizar una consulta SQL que devuelva todos los clientes que durante
2 años consecutivos compraron al menos 5 productos distintos. 

De esos clientes mostrar:
• El codigo de cliente
• El monto total comprado en el 2012
• La cantidad de unidades de productos compradas en el 2012

El resultado debe ser ordenado primero por aquellos clientes que compraron
solo productos compuestos en algun momento, luego el resto.

Nota: No se permiten select en el from, es decir, select from (select ...) as T ...
*/

SELECT
	F.fact_cliente as Cliente,
	SUM(F.fact_total) as [Monto Total 2012],
	SUM(DISTINCT IT.item_cantidad) as [Unidades Compradas 2012]
FROM Factura F
	INNER JOIN Item_Factura IT ON
		F.fact_numero + F.fact_sucursal + F.fact_numero = IT.item_numero + IT.item_sucursal + IT.item_numero
	WHERE YEAR(F.fact_fecha) = 2012
	GROUP BY F.fact_cliente
	HAVING
		(
			SELECT TOP 1 COUNT(DISTINCT IT2.item_producto) + COUNT(DISTINCT IT3.item_producto) 
			FROM Factura F2 
				INNER JOIN Item_Factura IT2 ON
					F2.fact_numero + F2.fact_sucursal + F2.fact_numero = IT2.item_numero + IT2.item_sucursal + IT2.item_numero
				INNER JOIN Factura F3 ON
					F3.fact_cliente = F2.fact_cliente
				INNER JOIN Item_Factura IT3 ON
					F3.fact_numero + F3.fact_sucursal + F3.fact_numero = IT3.item_numero + IT3.item_sucursal + IT3.item_numero
			WHERE F2.fact_cliente = F.fact_cliente AND (DATEDIFF(YEAR,F2.fact_fecha,F3.fact_fecha) = 1) AND IT3.item_producto != IT2.item_producto
			GROUP BY YEAR(F2.fact_fecha),YEAR(F3.fact_fecha)
			ORDER BY COUNT(DISTINCT IT2.item_producto) + COUNT(DISTINCT IT3.item_producto) DESC
		) > 4
	ORDER BY CASE
		WHEN 
			F.fact_cliente IN (
								SELECT DISTINCT F4.fact_cliente
								FROM Factura F4
									INNER JOIN Item_Factura IT4 ON
										F4.fact_numero + F4.fact_sucursal + F4.fact_numero = IT4.item_numero + IT4.item_sucursal + IT4.item_numero
									INNER JOIN Composicion C ON
										IT4.item_producto = C.comp_producto
								)
		THEN 1
		ELSE 2
		END ASC


/*
realiza una consulta SQL que devuelva todos los clientes que durante
2 aaños consecutivos compraron al menos 5 productos  distintos. 
De esos clientes mostrar.
• codigo cliente
• El monto total comprado en el 2012
• La cantidad de unidades de productos compradas  en el 2012

El resultado debe ser ordenado primero por aquellos clientes que compraron
solo productos compuestos en algún momento, luego el resto.
*/

SELECT
	c.clie_codigo
	,(
		SELECT SUM(f4.fact_total) FROM Factura f4
		WHERE f4.fact_cliente = c.clie_codigo AND YEAR(f4.fact_fecha) = 2012
	) monto_total_2012
	,(
		SELECT SUM(it2.item_cantidad) FROM Item_Factura it2
		JOIN Factura f5 ON f5.fact_numero = it2.item_numero AND f5.fact_sucursal = it2.item_sucursal AND f5.fact_tipo = it2.item_tipo
		WHERE f5.fact_cliente = c.clie_codigo AND YEAR(f5.fact_fecha) = 2012
	) cantidad_unidades_compradas_2012

FROM Cliente c
JOIN Factura f ON f.fact_cliente = c.clie_codigo
WHERE	5 <= (
				SELECT 
					COUNT(DISTINCT it.item_producto)
				FROM Item_Factura it
				INNER JOIN Factura f2 ON f2.fact_numero = it.item_numero AND f2.fact_sucursal = it.item_sucursal AND f2.fact_tipo = it.item_tipo
				WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) AND f2.fact_cliente = c.clie_codigo
			 ) AND
		5 <= (
				SELECT 
					COUNT(DISTINCT it.item_producto)
				FROM Item_Factura it
				INNER JOIN Factura f3 ON f3.fact_numero = it.item_numero AND f3.fact_sucursal = it.item_sucursal AND f3.fact_tipo = it.item_tipo
				WHERE YEAR(f3.fact_fecha) = YEAR(f.fact_fecha) + 1 AND f3.fact_cliente = c.clie_codigo
			 )
GROUP by c.clie_codigo
ORDER BY 
	CASE WHEN(
			SELECT COUNT(it3.item_producto)
			FROM Item_Factura it3
			INNER JOIN Factura f6 ON f6.fact_numero = it3.item_numero AND f6.fact_sucursal = it3.item_sucursal AND f6.fact_tipo = it3.item_tipo
			WHERE f6.fact_cliente = '00656' AND it3.item_producto NOT IN (SELECT comp_producto FROM Composicion) 
	) = 0 THEN 1 ELSE 0 END DESC


/* nota:7 sin comentarios del profesor.
1. Realizar una consulta SQL que muestre aquellos clientes que en 2
años consecutivos compraron.
De estos clientes mostrar
	iEl código de cliente.
	iii.El nombre del cliente.
	iv.El numero de rubros que compro el cliente.
	La cantidad de productos con composición que compro el cliente en el 2012.

El resultado deberá ser ordenado por cantidad de facturas del cliente en toda la historia, de manera ascendente.

Nota: No se permiten select en el from, es decir, select ... from (select ...) as T,
*/



SELECT 
	CL.clie_codigo,
	CL.clie_razon_social as nombre_cliente,
	COUNT(DISTINCT P.prod_rubro) AS [numero de rubros que compro el cliente],
	(
		SELECT	COUNT (DISTINCT C1.comp_producto)
		FROM Factura F2
			INNER JOIN Item_Factura I2
				ON F2.fact_tipo+F2.fact_sucursal+F2.fact_numero=I2.item_tipo+I2.item_sucursal+I2.item_numero
			 INNER JOIN Composicion C1
				ON C1.comp_producto = I2.item_producto
		WHERE YEAR(F2.fact_fecha) = 2012 AND F2.fact_cliente = CL.clie_codigo
	) AS [La cantidad de productos con composición que compro el cliente en el 2012]
	
FROM Cliente CL 
	INNER JOIN Factura F 
		ON F.fact_cliente = CL.clie_codigo
	INNER JOIN Item_Factura I 
		ON F.fact_tipo+F.fact_sucursal+F.fact_numero=I.item_tipo+I.item_sucursal+I.item_numero
	JOIN Producto P 
		ON P.prod_codigo = I.item_producto

WHERE	0 < ( 
				SELECT 
					COUNT(DISTINCT I5.item_producto)
				FROM Item_Factura I5
				INNER JOIN Factura F5 ON F5.fact_numero = I5.item_numero AND F5.fact_sucursal = I5.item_sucursal AND F5.fact_tipo = I5.item_tipo
				WHERE YEAR(F5.fact_fecha) = YEAR(f.fact_fecha) AND F5.fact_cliente = CL.clie_codigo
			 ) AND
		0 < (
				SELECT 
					COUNT(DISTINCT I6.item_producto)
				FROM Item_Factura I6
				INNER JOIN Factura F6 ON F6.fact_numero = I6.item_numero AND F6.fact_sucursal = I6.item_sucursal AND F6.fact_tipo = I6.item_tipo
				WHERE YEAR(F6.fact_fecha) = YEAR(f.fact_fecha) + 1 AND F6.fact_cliente = CL.clie_codigo
			 )

GROUP BY CL.clie_codigo,CL.clie_razon_social

ORDER BY COUNT(DISTINCT F.fact_tipo+F.fact_sucursal+F.fact_numero) ASC




--------------------
-- 2da version: NOTA: 8 : sin comentarios del profesor
-----------


--Ejercicio 1. 
select 
	c.clie_codigo codigoCliente,
	c.clie_razon_social nombreCliente,
	count(distinct p.prod_rubro) cantidadRubros,
	isnull((select sum(ifa.item_cantidad) from Item_Factura ifa join Factura fact on ifa.item_tipo=fact.fact_tipo and ifa.item_sucursal= fact.fact_sucursal and ifa.item_numero = fact.fact_numero 
	 join Composicion on comp_producto = ifa.item_producto
	 where YEAR(fact.fact_fecha) = 2012 and fact.fact_cliente = c.clie_codigo ),0) productosCompuestosCompradosEn2012 
from Cliente c join Factura f on f.fact_cliente = c.clie_codigo
join Item_Factura i on f.fact_tipo= i.item_tipo and f.fact_sucursal = i.item_sucursal and f.fact_numero = i.item_numero 
join Producto p on p.prod_codigo = i.item_producto
where exists 
(select 1 from Item_Factura it
inner join Factura f2 on f2.fact_numero = it.item_numero and f2.fact_sucursal = it.item_sucursal and f2.fact_tipo = it.item_tipo
where YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) and f2.fact_cliente = c.clie_codigo ) and 
exists
(select 1 from  Item_Factura it2
inner join Factura f3 on f3.fact_numero = it2.item_numero and f3.fact_sucursal = it2.item_sucursal and f3.fact_tipo = it2.item_tipo
where YEAR(f3.fact_fecha) = YEAR(f.fact_fecha) + 1 and f3.fact_cliente = c.clie_codigo ) 
group by c.clie_codigo, c.clie_razon_social
order by count(distinct f.fact_tipo+f.fact_sucursal+f.fact_numero) asc


/* 
se asumió que al decir "cantidad de productos con composicion" se refiere a sumatoria de unidades de productos con composicion que el cliente
compro en 2012, si en cambio fuera cantidad de productos compuestos distintos que compro en 2012 en la linea 5 seria count(distinct(comp_producto))
en lugar de sum(item_cantidad)
*/ 

/*I.  

	AUN NO COMPARADO CON OTRA PERSONA

Realizar una consulta SQL que permita saber los clientes que compraron en el 2012 al menos 1 unidad de todos los productos compuestos.

De estos clientes mostrar, siempre para el 2012:
		I. El código del cliente
		2. Código de producto que en cantidades más compro.
?? 3. El número de fila según el orden establecido con un alias llamado ORDINAL. 
		4. Cantidad de productos distintos comprados por el cliente.
		5. Monto total comprado.

El resultado deberá ser ordenado por razón social del cliente
alfabéticamente primero y luego, los clientes que compraron entre un
20 % y 30% del total facturado en el 2012 primero, luego, los restantes.*/

SELECT
	CL1.clie_codigo,
	(
		SELECT TOP 1 I2.item_producto  
			FROM Factura F2 
			INNER JOIN Item_Factura I2 
				ON  I2.item_tipo = F2.fact_tipo AND
					I2.item_sucursal = F2.fact_sucursal AND
					I2.item_numero = F2.fact_numero
			WHERE F2.fact_cliente = CL1.clie_codigo AND YEAR(F2.fact_fecha) = 2012
			GROUP BY I2.item_producto
			ORDER BY SUM(I2.item_cantidad) DESC

	) AS CODIGO_PRODUCTO_MAS_COMPRADO,

	COUNT(DISTINCT I1.item_producto) AS CANTIDAD_PRODUCTOS_DISTINTOS_COMPRADOS,

	SUM(F1.fact_total) AS MONTO_TOTAL_COMPRADO,
	COUNT(DISTINCT COMPO.comp_producto)

FROM Cliente CL1
	INNER JOIN Factura F1 
		ON CL1.clie_codigo = F1.fact_cliente
	INNER JOIN Item_Factura I1 
		ON F1.fact_tipo+F1.fact_sucursal+F1.fact_numero=I1.item_tipo+I1.item_sucursal+I1.item_numero
	LEFT JOIN Composicion COMPO
		ON COMPO.comp_producto = I1.item_producto
		
WHERE  YEAR(F1.fact_fecha) = 2012
GROUP BY CL1.clie_codigo
HAVING  (-- ESTA BIEN HECHO PERO NO HAY PRODUCTOS Q CUMPLAN CONDICION
			SELECT COUNT(DISTINCT COM.comp_producto)
			FROM Composicion COM 
		) = COUNT(DISTINCT COMPO.comp_producto)
--ORDER BY PENDIENTE :(

----------------------------Fin parciales sin resolver---------------------------

------------------------------Inicio guia resuelta en partes--------------------------
--1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
--igual a $ 1000 ordenado por código de cliente

select clie_codigo, clie_razon_social from dbo.Cliente where clie_limite_credito >= 1000
order by clie_codigo 

--2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
--cantidad vendida.
--Left 17327 y inner join lo mismo

select prod.prod_codigo, prod.prod_detalle, item.item_cantidad 
from dbo.Producto prod 
 inner join dbo.Item_Factura item on 
	item.item_producto = prod.prod_codigo
 inner join dbo.Factura fact on 
	fact.fact_tipo = item.item_tipo and 
	fact.fact_numero = item.item_numero and 
	fact.fact_sucursal = item.item_sucursal
 where year(fact.fact_fecha) = 2012
 order by item_cantidad
--3. Realizar una consulta que muestre código de producto, nombre de producto y el stock
--total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
--nombre del artículo de menor a mayor

--Hipotesis: Se muestran los productos que tienen stock, en caso de no estar en el stock sera null(Left join), caso de ver solo los que existen en ambas tablas(Inner Join)
select 
	prod.prod_codigo, 
	prod.prod_detalle,
	isnull(SUM(stock.stoc_cantidad),0) as stock_total
from dbo.Producto prod 
	left join dbo.STOCK stock on
	stock.stoc_producto = prod.prod_codigo
group by prod.prod_codigo, prod.prod_detalle
order by prod.prod_detalle asc

select SUM(stoc_cantidad) FROM dbo.STOCK stock   WHERE stoc_producto = '00000102'

--4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
--artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
--promedio por depósito sea mayor a 100.
--Nota del promedio, ojo que la composicion multiplica nuestros registros de productoXstock
select 
prod_codigo, 
prod_detalle,
COUNT(distinct comp_componente) as cantidad_articulos,
avg(stoc_cantidad) as promedio
from Producto prod
inner join dbo.STOCK stoc on -- Traemos productos que esten en algun stock, porque nos piden filtrar por stoc cantidad. No nos sirve tenerlos nulos, y luego calcular having
	prod.prod_codigo = stoc.stoc_producto
left join dbo.Composicion comp on --Left para no perder productos que no tengan  combos
	comp.comp_producto = prod.prod_codigo
--where prod_codigo = '00000806' 
group by prod_codigo, prod_detalle
having avg(stoc_cantidad) > 100


--5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
--stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
--fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.

select --prod.prod_codigo, COUNT(*)
prod.prod_codigo, prod.prod_detalle,
SUM(item.item_cantidad)

from Producto prod 
--inner join STOCK stoc on stoc.stoc_producto = prod.prod_codigo
inner join Item_Factura item on item.item_producto = prod.prod_codigo
inner join Factura fac 
on fac.fact_numero = item.item_numero and fac.fact_sucursal = item.item_sucursal and fac.fact_tipo = item.item_tipo
where YEAR(fac.fact_fecha) = 2012 --and prod.prod_codigo = '00010719'
group by prod.prod_codigo, prod.prod_detalle
having SUM(item.item_cantidad) > (SELECT SUM(item_aux.item_cantidad) FROM Factura fac_aux inner join Item_Factura item_aux  
on fac_aux.fact_numero = item_aux.item_numero and fac_aux.fact_sucursal = item_aux.item_sucursal and fac_aux.fact_tipo = item_aux.item_tipo
where YEAR(fac_aux.fact_fecha) = 2011 and item_aux.item_producto = prod.prod_codigo)

--6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
--rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
--tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.

select 
ru.rubr_id, 
ru.rubr_detalle, 
COUNT(distinct prod.prod_codigo) cantidad_prod,
SUM(stoc.stoc_cantidad) sum_total
from dbo.Producto prod 
inner join dbo.Rubro ru on 
	ru.rubr_id = prod.prod_rubro
inner join dbo.STOCK stoc on 
	stoc.stoc_producto = prod.prod_codigo
--WHERE stoc.stoc_producto is null
where (select sum(stoc_aux.stoc_cantidad) from stock stoc_aux where stoc_aux.stoc_producto= prod.prod_codigo ) >
(select SUM(stoc_cantidad) from dbo.STOCK where stoc_producto =  '00000000' and stoc_deposito= '00')
group by ru.rubr_id, ru.rubr_detalle 

--7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio
--menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
--10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
--stock.

select 
prod.prod_codigo, 
prod_detalle, 
max(prod.prod_precio) maximo_precio, 
min(prod.prod_precio) minimo_precio,
case when min(prod.prod_precio) = 0 then 0 else ((max(prod.prod_precio) - min(prod.prod_precio ) / min(prod.prod_precio))) * 100 end
from dbo.Producto prod
inner join dbo.STOCK stoc on stoc.stoc_producto = prod.prod_codigo
--where stoc.stoc_cantidad > 0
group by prod.prod_codigo, prod_detalle
having SUM(stoc.stoc_cantidad) > 0

-- o tambien
select 
prod.prod_codigo, 
prod_detalle, 
max(item.item_precio) maximo_precio, 
min(item.item_precio) minimo_precio,
--(max(item.item_precio) - min(item.item_precio ) * 100 / min(item.item_precio)) diferencia
((MAX(item.item_precio)-MIN(item.item_precio))*100)/MIN(item.item_precio) AS [Diferencia de Precios]
from dbo.Producto prod
inner join dbo.STOCK stoc on stoc.stoc_producto = prod.prod_codigo
inner join dbo.Item_Factura item on item.item_producto = prod.prod_codigo
--where stoc.stoc_cantidad > 0
group by prod.prod_codigo, prod_detalle
having SUM(stoc.stoc_cantidad) > 0

--8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
--artículo, stock del depósito que más stock tiene.

select 
prod.prod_codigo, 
prod_detalle,
--stoc.stoc_deposito,
sum(stoc.stoc_cantidad) suma_total,
max(stoc.stoc_cantidad) stock_deposito_maximo,
count(distinct stoc.stoc_deposito) cantidad_depositos
--(select stoc_aux.stoc_deposito from dbo.STOCK stoc_aux where stoc_aux.stoc_producto = prod.prod_codigo) deposito_asociado
from dbo.Producto prod 
inner join dbo.STOCK stoc on 
	stoc.stoc_producto = prod.prod_codigo
--where prod.prod_codigo = '00000102'
group by  prod.prod_codigo, prod_detalle--,stoc.stoc_deposito
having COUNT(distinct stoc.stoc_deposito) = (select count(distinct stoc.stoc_deposito) 
											from dbo.STOCK stoc)
order by prod.prod_codigo desc

--10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
--vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
--mayor compra realizo.

select fact_aux.fact_cliente, sum(item.item_cantidad), item_producto
	from dbo.Item_Factura item
	inner join Factura fact_aux on fact_aux.fact_numero = item.item_numero and fact_aux.fact_sucursal = item.item_sucursal and fact_aux.fact_tipo = item.item_tipo
	where '00001420' = item.item_producto
	group by fact_aux.fact_cliente, item_producto
	order by sum(item.item_cantidad) desc
------------
select prod.prod_codigo, prod.prod_detalle, COUNT(*), 
(select top 1 fact_aux.fact_cliente 
	from dbo.Item_Factura item
	inner join Factura fact_aux on fact_aux.fact_numero = item.item_numero and fact_aux.fact_sucursal = item.item_sucursal and fact_aux.fact_tipo = item.item_tipo
	where prod.prod_codigo = item.item_producto
	group by fact_aux.fact_cliente
	order by sum(item.item_cantidad) desc
) as cliente_mayor_compra 
from Producto prod
---inner join Item_Factura item on item.item_producto = prod.prod_codigo
---inner join Factura fact on fact.fact_numero = item.item_numero and fact.fact_sucursal = item.item_sucursal and fact.fact_tipo = item.item_tipo
--inner join Cliente clie on clie.clie_codigo = fact.fact_cliente
where prod.prod_codigo in (select top 10 item_aux.item_producto from Item_Factura item_aux 
							group by item_aux.item_producto
							order by sum(item_aux.item_cantidad) desc)
	or prod.prod_codigo in (select top 10 item_aux.item_producto from Item_Factura item_aux 
							group by item_aux.item_producto
							order by sum(item_aux.item_cantidad) asc)
group by prod_codigo, prod_detalle
--having COUNT(*) > 1
order by prod_codigo



--11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
--productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
--ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
--solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
--el año 2012.

select 
fami.fami_id,
fami.fami_detalle, 
count(distinct prod.prod_codigo) cantidad_productos_diferentes,
sum(item.item_cantidad * item.item_precio) monto
from dbo.Producto prod 
inner join dbo.Familia fami on fami.fami_id = prod.prod_familia
inner join dbo.Item_Factura item on item.item_producto = prod.prod_codigo
inner join dbo.Factura fact on fact.fact_sucursal = item.item_sucursal and fact.fact_numero = item.item_numero and fact.fact_tipo = item.item_tipo
where year(fact.fact_fecha) = 2012
group by fami.fami_id,fami.fami_detalle
having sum(item.item_cantidad * item.item_precio) > 20000
order by count(distinct prod.prod_codigo) desc

--o tambien podes entender Dame las familias que tengan al menos una factura individual mayor a $20.000 en el año 2012. 
--Aca tener encuenta si hay factura de 15000 y 10000 de una familia no la muestra, pero el total es 250000. Ojo

select 
fami.fami_id,
fami.fami_detalle, 
count(distinct prod.prod_codigo) cantidad_productos_diferentes,
sum(item.item_cantidad * item.item_precio) monto
from dbo.Producto prod 
inner join dbo.Familia fami on fami.fami_id = prod.prod_familia
inner join dbo.Item_Factura item on item.item_producto = prod.prod_codigo
inner join dbo.Factura fact on fact.fact_sucursal = item.item_sucursal and fact.fact_numero = item.item_numero and fact.fact_tipo = item.item_tipo
group by fami.fami_id,fami.fami_detalle
having exists (
select top 1 fact_aux.fact_tipo, fact_aux.fact_sucursal, fact_aux.fact_numero from Item_Factura item_aux 
inner join Factura fact_aux on
fact_aux.fact_sucursal = item_aux.item_sucursal and fact_aux.fact_numero = item_aux.item_numero and fact_aux.fact_tipo = item_aux.item_tipo
inner join Producto prod_aux on prod_aux.prod_codigo = item_aux.item_producto
where year(fact_aux.fact_fecha) = 2012 and prod_aux.prod_familia = fami.fami_id
group by fact_aux.fact_tipo, fact_aux.fact_sucursal, fact_aux.fact_numero
having sum(item_aux.item_cantidad * item_aux.item_precio) > 20000)
  

--12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe
--promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
--producto y stock actual del producto en todos los depósitos. Se deberán mostrar
--aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
--ordenarse de mayor a menor por monto vendido del producto.

select --* 
prod.prod_codigo,
prod.prod_detalle,
count(distinct fact.fact_cliente) clientes_distintos,
AVG(item.item_precio) as importe_promedio_pagado,
(SELECT count(distinct stoc.stoc_deposito) FROM dbo.STOCK stoc where stoc.stoc_producto = prod.prod_codigo and isnull(stoc_cantidad,0) > 0) cantidad_depositos,
(SELECT sum( stoc. stoc_cantidad) FROM dbo.STOCK stoc where stoc.stoc_producto = prod.prod_codigo) total_stock
from dbo.Producto prod
inner join Item_Factura item on item.item_producto = prod.prod_codigo
inner join dbo.Factura fact on fact.fact_sucursal = item.item_sucursal and fact.fact_numero = item.item_numero and fact.fact_tipo = item.item_tipo
where YEAR(fact.fact_fecha) = 2012
group by prod.prod_codigo,
prod.prod_detalle
ORDER BY SUM(item.item_precio * item.item_cantidad) DESC

-------------------------

select
*
--AVG(item.item_precio)
--count(distinct fact.fact_cliente) clientes_distintos
from dbo.Producto prod
inner join Item_Factura item on item.item_producto = prod.prod_codigo
inner join dbo.Factura fact on fact.fact_sucursal = item.item_sucursal and fact.fact_numero = item.item_numero and fact.fact_tipo = item.item_tipo
where YEAR(fact.fact_fecha) = 2012 and prod_codigo = '00010220'
-----------------------------
select sum(stoc_cantidad) from STOCK where stoc_producto = '00000102'

--13. Realizar una consulta que retorne para cada producto que posea composición nombre
--del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
--de los productos que lo componen. Solo se deberán mostrar los productos que estén
--compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
-- cantidad de productos que lo componen.

select 
prod.prod_codigo, 
prod.prod_detalle, 
prod.prod_precio,
SUM(comp.comp_cantidad * prod_aux.prod_precio),
COUNT(distinct comp_componente) as cantidad_componentes  
from dbo.Producto prod 
inner join dbo.Composicion comp on comp.comp_producto = prod.prod_codigo
inner join dbo.Producto prod_aux on prod_aux.prod_codigo = comp.comp_componente
group by prod.prod_codigo, prod.prod_detalle, prod.prod_precio
having COUNT(distinct comp_componente) >= 2
order by COUNT(distinct comp_componente) desc


--14. Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que
--debe retornar son:
--Código del cliente
--Cantidad de veces que compro en el último año
--Promedio por compra en el último año
--Cantidad de productos diferentes que compro en el último año
--Monto de la mayor compra que realizo en el último año
--Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
--el último año.
--No se deberán visualizar NULLs en ninguna columna

select 
fact.fact_cliente,
count(distinct fact.fact_numero+fact.fact_sucursal+fact.fact_tipo) cantidad_veces_que_compro,
--avg(fact.fact_total) as promedio_por_compra_malo,--Mal porque apertura por items, caga el promedio
(select avg(fact_total) from Factura 
	where fact_cliente = fact.fact_cliente 
	and year(fact_fecha) = (SELECT max(year(maximo.fact_fecha)) FROM dbo.Factura maximo)) promedio_compra_factura, 
count(distinct item.item_producto) as cantidad_productos_diferentes,
(select top 1  fac_top.fact_total from dbo.Factura fac_top 
	where fac_top.fact_cliente = fact.fact_cliente and 
	year(fac_top.fact_fecha) = (SELECT max(year(fact_fecha)) FROM dbo.Factura)
	order by fact_total desc) monto_mayor_compra
--(select top 1 fact_mayor.fact_numero+fact_sucursal+fact_tipo from Factura fact_mayor 
--where fact_mayor.fact_cliente = fact.fact_cliente and year(fact_mayor.fact_fecha) = (SELECT max(year(fact_fecha)) FROM dbo.Factura)
--group by fact_mayor.fact_numero,fact_sucursal, fact_tipo
--order by SUM(fact_mayor.fact_total) desc) as monto_mayor_factura

from dbo.Factura fact 
	inner join Item_Factura item 
on item.item_numero = fact.fact_numero and item.item_sucursal = fact.fact_sucursal and item.item_tipo = fact.fact_tipo
where year(fact.fact_fecha) = (select max(YEAR(fact_aux.fact_fecha)) from dbo.Factura fact_aux) --and fact_cliente = '01743' 
group by fact.fact_cliente
order by count(distinct fact.fact_numero+fact.fact_sucursal+fact.fact_tipo) desc


--15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
--(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
--descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
--juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
--juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
--Ejemplo de lo que retornaría la consulta:
--PROD1 DETALLE1 PROD2 DETALLE2 VECES
---1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
--1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2
--Revisar en un futuro, es interesante
select 
prod1.prod_codigo, 
prod1.prod_detalle, 
prod2.prod_codigo, 
prod2.prod_detalle,
COUNT(distinct item1.item_numero+item1.item_sucursal+item1.item_tipo)
from Item_Factura item1 
inner join Item_Factura item2 on item1.item_numero = item2.item_numero and item1.item_sucursal = item2.item_sucursal and item1.item_tipo = item2.item_tipo
inner join dbo.Producto prod1 on prod1.prod_codigo = item1.item_producto
inner join dbo.Producto prod2 on prod2.prod_codigo = item2.item_producto
--where item1.item_numero = '00092444' and item1.item_sucursal = '0003' and item1.item_tipo = 'A'
where item1.item_producto < item2.item_producto --Evito que me traiga el par consigo mismo
group by prod1.prod_codigo, prod1.prod_detalle, prod2.prod_codigo, prod2.prod_detalle
having COUNT(*) > 500
--COUNT(distinct item1.item_numero+item1.item_sucursal+item1.item_tipo) > 500
order by 5 desc
------------------------
--16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
--en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
--inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
--Además mostrar
--1. Nombre del Cliente
--2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
--3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
--mostrar solamente el de menor código) para ese cliente.
--Aclaraciones:
--La composición es de 2 niveles, es decir, un producto compuesto solo se compone de
--productos no compuestos.
--Los clientes deben ser ordenados por código de provincia ascendente.

select  clie.clie_razon_social, 
SUM(item.item_cantidad) as cantidad_unidades_totales,
(select top 1 item2.item_producto from dbo.Item_Factura item2 
	inner join dbo.Factura fac2 on fac2.fact_sucursal = item2.item_sucursal and fac2.fact_numero = item2.item_numero and fac2.fact_tipo = item2.item_tipo
    where fac2.fact_cliente = clie.clie_codigo and  YEAR(fac2.fact_fecha) = 2012
	group by item2.item_producto 
	order by SUM(item2.item_cantidad) desc, item2.item_producto asc) as producto_mayor_ventas
from dbo.Cliente clie 
inner join dbo.Factura fac on fac.fact_cliente = clie.clie_codigo
inner join dbo.Item_Factura item on fac.fact_numero = item.item_numero and fac.fact_sucursal = item.item_sucursal and fac.fact_tipo = item.item_tipo 
where YEAR(fac.fact_fecha) = 2012
group by clie.clie_razon_social, clie.clie_codigo, clie.clie_domicilio
having SUM(item.item_cantidad) > 1/3 * (select  --item3.item_producto, 
												top 1 SUM(item3.item_cantidad) from Item_Factura item3 
										inner join dbo.Factura fact3 on 
										fact3.fact_sucursal = item3.item_sucursal and fact3.fact_numero = item3.item_numero and fact3.fact_tipo = item3.item_tipo
										where year(fact3.fact_fecha) = 2012
										group by item3.item_producto
										order by SUM(item3.item_cantidad) desc )
order by clie.clie_domicilio asc
---------------------------------------------------------------REVISAR 16--------------------------------------------------------

--17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
--producto.
--La consulta debe retornar:
--PERIODO: Año y mes de la estadística con el formato YYYYMM
--PROD: Código de producto
--DETALLE: Detalle del producto
--CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
--VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
--pero del año anterior
--CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
--periodo
--La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
--por periodo y código de producto.

select * from dbo.Item_Factura item 
inner join dbo.Factura fac on fac.fact_numero = item.item_numero and fac.fact_sucursal = item.item_sucursal and fac.fact_tipo = item.item_tipo 
where item.item_producto = '00010200' and YEAR(fac.fact_fecha) = 2012 and MONTH(fac.fact_fecha) = 7


select 
year(fac.fact_fecha) anio, 
MONTH(fac.fact_fecha) mes, 
--FORMAT(fac.fact_fecha, 'yyyyMM') periodo,
CONVERT(VARCHAR(6), fac.fact_fecha, 112) periodo,
prod.prod_codigo as codigo_producto, 
prod_detalle as detalle_producto,
sum(item.item_cantidad) as cantidad_vendida,
isnull((select SUM(item2.item_cantidad) from dbo.Factura fac2 
			inner join dbo.item_factura item2 
			on fac2.fact_numero = item2.item_numero and fac2.fact_sucursal = item2.item_sucursal and fac2.fact_tipo = item2.item_tipo
			where item2.item_producto = prod.prod_codigo and (YEAR(fac.fact_fecha) - 1) = YEAR(fac2.fact_fecha) and MONTH(fac2.fact_fecha) = MONTH(fac.fact_fecha)),0) 
			ventas_anio_anterior,
--(select COUNT(fac2.fact_sucursal+fac2.fact_numero+fac2.fact_tipo) 
--from dbo.Factura fac2 
--inner join dbo.item_factura item2 
--on fac2.fact_numero = item2.item_numero and fac2.fact_sucursal = item2.item_sucursal and fac2.fact_tipo = item2.item_tipo
--where item2.item_producto = prod.prod_codigo and YEAR(fac.fact_fecha) = YEAR(fac2.fact_fecha) and MONTH(fac2.fact_fecha) = MONTH(fac.fact_fecha)) cantidad_facturas,
COUNT(fac.fact_sucursal+fac.fact_numero+fac.fact_tipo) as cantidad_facturas
from Producto prod
inner join dbo.Item_Factura item on item.item_producto = prod.prod_codigo
inner join dbo.Factura fac on fac.fact_numero = item.item_numero and fac.fact_sucursal = item.item_sucursal and fac.fact_tipo = item.item_tipo
group by year(fac.fact_fecha), MONTH(fac.fact_fecha), prod.prod_codigo, prod_detalle, CONVERT(VARCHAR(6), fac.fact_fecha, 112)
--FORMAT(fac.fact_fecha, 'yyyyMM') 
order by 3,4

--18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
--La consulta debe retornar:
--DETALLE_RUBRO: Detalle del rubro
--VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
--PROD1: Código del producto más vendido de dicho rubro
--PROD2: Código del segundo producto más vendido de dicho rubro
--CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
---días
--La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
--por cantidad de productos diferentes vendidos del rubro.

select 
ru.rubr_id, 
ru.rubr_detalle, 
SUM(item.item_cantidad* item.item_precio) monto_total,
ISNULL((select top 1 prod2.prod_codigo from Producto prod2 
	inner join Item_Factura item2 on prod2.prod_codigo = item2.item_producto 
	where prod2.prod_rubro = ru.rubr_id
	group by prod2.prod_codigo
 	order by SUM(item2.item_cantidad* item2.item_precio) desc),0) maximo_vendido_primero,
ISNULL((select top 1 prod2.prod_codigo from Producto prod2 
	inner join Item_Factura item2 on prod2.prod_codigo = item2.item_producto 
	where prod2.prod_rubro = ru.rubr_id and prod2.prod_codigo <> (select top 1 prod2.prod_codigo from Producto prod2 
																	inner join Item_Factura item2 on prod2.prod_codigo = item2.item_producto 
																	where prod2.prod_rubro = ru.rubr_id
																	group by prod2.prod_codigo
 																	order by SUM(item2.item_cantidad* item2.item_precio) desc)
	group by prod2.prod_codigo
 	order by SUM(item2.item_cantidad* item2.item_precio) desc),0) maximo_vendido_segundo,
ISNULL((select top 1 fact2.fact_cliente from Producto prod2 
	inner join Item_Factura item2 on prod2.prod_codigo = item2.item_producto 
	inner join Factura fact2 on fact2.fact_numero = item2.item_numero and fact2.fact_sucursal = item2.item_sucursal and fact2.fact_tipo = item2.item_tipo
	where prod2.prod_rubro = ru.rubr_id and fact_fecha > DATEADD(DAY, -30, (select max(fact3.fact_fecha) from dbo.Factura fact3 ) )
	group by fact2.fact_cliente
 	order by SUM(item2.item_cantidad) desc),0) cliente_maximo

from Rubro ru 
inner join Producto prod on prod.prod_rubro = ru.rubr_id
inner join Item_Factura item on prod.prod_codigo = item.item_producto
group by ru.rubr_id, ru.rubr_detalle
order by count(distinct prod.prod_codigo)

------------------------------------------------

select * 
--prod.prod_codigo, sum(item.item_cantidad* item.item_precio)
from Rubro ru 
inner join Producto prod on prod.prod_rubro = ru.rubr_id
inner join Item_Factura item on prod.prod_codigo = item.item_producto
inner join Factura fact2 on fact2.fact_numero = item.item_numero and fact2.fact_sucursal = item.item_sucursal and fact2.fact_tipo = item.item_tipo
where ru.rubr_id = '0017' and  fact2.fact_fecha > DATEADD(DAY, -30, (select max(fact3.fact_fecha) from dbo.Factura fact3 ) )
--group by prod.prod_codigo
order by item.item_cantidad desc

--Validacion para cada producto y factura solo existe una vez en la factura(El item no puede aparecer por separado en una factura)
select prod.prod_codigo,fact2.fact_numero+fact2.fact_sucursal+fact2.fact_tipo, COUNT(*)
--prod.prod_codigo, sum(item.item_cantidad* item.item_precio)
from Rubro ru 
inner join Producto prod on prod.prod_rubro = ru.rubr_id
inner join Item_Factura item on prod.prod_codigo = item.item_producto
inner join Factura fact2 on fact2.fact_numero = item.item_numero and fact2.fact_sucursal = item.item_sucursal and fact2.fact_tipo = item.item_tipo
group by prod.prod_codigo, fact2.fact_numero+fact2.fact_sucursal+fact2.fact_tipo--, COUNT(fact2.fact_numero+fact2.fact_sucursal+fact2.fact_tipo)
having COUNT(*) > 1

--19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
--solicita que desarrolle una consulta sql que retorne para todos los productos:
-- Codigo de producto
-- Detalle del producto
-- Codigo de la familia del producto
-- Detalle de la familia actual del producto
-- Codigo de la familia sugerido para el producto
-- Detalla de la familia sugerido para el producto
--La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
--detalle coinciden en los primeros 5 caracteres.
--En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
--codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
--diferente a la sugerida
--Los resultados deben ser ordenados por detalle de producto de manera ascendente

select 
prod.prod_codigo, 
prod_detalle, 
fami.fami_id, 
fami.fami_detalle, 
(select fami2.fami_detalle from dbo.Familia fami2 
where fami2.fami_id = (select top 1 prod2.prod_familia from Producto prod2
								where left(prod.prod_detalle, 5) = left(prod2.prod_detalle,5)
								group by prod2.prod_familia
								order by COUNT(*) desc, prod2.prod_familia asc)) familia_seguerida, --Dar bola, el order by sin esto se complica. Deberia agrupar y se complica
(select top 1 prod2.prod_familia from Producto prod2
								where left(prod.prod_detalle, 5) = left(prod2.prod_detalle,5)
								group by prod2.prod_familia
								order by COUNT(*) desc, prod2.prod_familia asc) id_sugerido
--(select top 1 fami2.fami_id from Producto prod2 
--	inner join Familia fami2 on prod2.prod_familia = fami2.fami_id
--	where left(prod.prod_detalle,5) = left(prod2.prod_detalle,5)
--	group by fami2.fami_id
--order by COUNT(fami2.fami_detalle) desc, prod2.prod_codigo asc)
from Producto prod inner join Familia fami on fami.fami_id = prod.prod_familia
where fami.fami_id <> (select top 1 prod3.prod_familia from Producto prod3
								where left(prod.prod_detalle, 5) = left(prod3.prod_detalle,5)
								group by prod3.prod_familia
								order by COUNT(*) desc, prod3.prod_familia asc)
--group by prod.prod_codigo, prod_detalle, fami.fami_id, fami.fami_detalle
---having COUNT(*) > 1
order by prod.prod_detalle

select fami2.fami_detalle, COUNT(fami2.fami_detalle) 
    from Producto prod2 
	inner join Familia fami2 on prod2.prod_familia = fami2.fami_id
	where 'HALLS'                                    = left(prod2.prod_detalle,5)
	group by fami2.fami_detalle--,prod2.prod_codigo 
	order by COUNT( fami2.fami_detalle) desc--, prod2.prod_codigo asc

select prod2.prod_familia, COUNT(*) from Producto prod2
where 'HALLS'                                    = left(prod2.prod_detalle,5)
group by prod2.prod_familia
order by COUNT(*) desc, prod2.prod_familia asc

--20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
--Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
--2012. El puntaje de cada empleado se calculara de la siguiente manera: para los que
--hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
--que superen los 100 pesos que haya vendido en el año, para los que tengan menos de 50
--facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas
--por sus subordinados directos en dicho año.

--Revisar

SELECT 
Emp.empl_nombre, 
Emp.empl_apellido, 
Emp.empl_ingreso, 
Emp.empl_codigo,
case 
	when (select COUNT(fact_numero+fact_sucursal+fact_tipo) from Factura fact where fact.fact_vendedor = Emp.empl_codigo and YEAR(fact_fecha) = 2011) >= 50
	then(
		select  COUNT(fact2.fact_numero+fact2.fact_sucursal+fact2.fact_tipo) 
		from dbo.Factura fact2
		where fact2.fact_vendedor = Emp.empl_codigo and 
			YEAR(fact2.fact_fecha) = 2011 and 
			fact2.fact_total > 100
	)
	else 
	(
		select  COUNT(fact3.fact_numero+fact3.fact_sucursal+fact3.fact_tipo) * 0.5
		from dbo.Factura fact3
		where fact3.fact_vendedor in (select emp2.empl_codigo from Empleado emp2 where emp2.empl_jefe = Emp.empl_codigo) and YEAR(fact3.fact_fecha) = 2011 
		--Ojo dice subordinados, darle bola. Dar tiempo para repasarlo
	)
END puntaje_2011,

case 
	when (select COUNT(fact_numero+fact_sucursal+fact_tipo) 
		from Factura fact where fact.fact_vendedor = Emp.empl_codigo and 
		YEAR(fact_fecha) = 2012) >= 50

	then(
		select  COUNT(fact2.fact_numero+fact2.fact_sucursal+fact2.fact_tipo) 
		from dbo.Factura fact2
		where fact2.fact_vendedor = Emp.empl_codigo and 
			YEAR(fact2.fact_fecha) = 2012 and 
			fact2.fact_total > 100
	)
	else 
	(
		select  COUNT(fact3.fact_numero+fact3.fact_sucursal+fact3.fact_tipo) * 0.5
		from dbo.Factura fact3
		where fact3.fact_vendedor in (select emp2.empl_codigo from Empleado emp2 where emp2.empl_jefe = Emp.empl_codigo) and YEAR(fact3.fact_fecha) = 2012 
		--Ojo dice subordinados, darle bola. Dar tiempo para repasarlo
	)
END puntaje_2012
	

FROM dbo.Empleado Emp


SELECT E.empl_codigo
	,E.empl_nombre
	,E.empl_apellido
	,E.empl_ingreso
	,CASE
		WHEN (
				SELECT COUNT(fact_vendedor)
				FROM Factura
				WHERE E.empl_codigo = fact_vendedor
					AND YEAR(fact_fecha) = 2011) >= 50 
		THEN (
				SELECT COUNT(*) 
				FROM FACTURA
				WHERE fact_total > 100
					AND E.empl_codigo = fact_vendedor
					AND YEAR(fact_fecha) = 2011
			)
		ELSE (
				SELECT COUNT(*) * 0.5
				FROM Factura
				WHERE fact_vendedor IN (
											SELECT empl_codigo
											FROM Empleado
											WHERE empl_jefe = E.empl_codigo
										)
					AND YEAR(fact_fecha) = 2011
			)													   
	END 'Puntaje 2011'
	,CASE
		WHEN (
				SELECT COUNT(fact_vendedor)
				FROM Factura
				WHERE E.empl_codigo = fact_vendedor
					AND YEAR(fact_fecha) = 2012) >= 50 
		THEN (
				SELECT COUNT(*) 
				FROM FACTURA
				WHERE fact_total > 100
					AND E.empl_codigo = fact_vendedor
					AND YEAR(fact_fecha) = 2012
			)
		ELSE (
				SELECT COUNT(*) * 0.5
				FROM Factura
				WHERE fact_vendedor IN (
											SELECT empl_codigo
											FROM Empleado
											WHERE empl_jefe = E.empl_codigo
										)
					AND YEAR(fact_fecha) = 2012
			)													   
	END 'Puntaje 2012'
FROM Empleado E


--Datos de los Jefes de los empleados
select *
from  Empleado emp1
inner join Empleado emp2 on emp1.empl_jefe = emp2.empl_codigo

--Datos de los jefes vinculaos con sus subordinados

select *
from  Empleado emp1 
inner join Empleado emp2 on emp2.empl_jefe = emp1.empl_codigo 

--21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
--menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta
--al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se
--considera que una factura es incorrecta cuando la diferencia entre el total de la factura
--menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
--los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
--son:
-- Año
-- Clientes a los que se les facturo mal en ese año
-- Facturas mal realizadas en ese año


select 
YEAR(fac.fact_fecha) anio, 
COUNT(DISTINCT fac.fact_cliente) as clientes_diferentes,
COUNT(fac.fact_cliente) as clientes_diferentes_v2,
COUNT(DISTINCT fac.fact_tipo+fac.fact_numero+fac.fact_sucursal) cantidad_facturas,
COUNT(fac.fact_tipo+fac.fact_numero+fac.fact_sucursal) cantidad_facturas_v2
from dbo.Factura fac 
where (fac.fact_total-fac.fact_total_impuestos) not between (select (SUM(item.item_cantidad* item.item_precio) - 1) from Item_Factura item
		where fac.fact_sucursal = item.item_sucursal and fac.fact_numero = item.item_numero and fac.fact_tipo = item.item_tipo)
 and (select (SUM(item.item_cantidad* item.item_precio) +1) from Item_Factura item
	where  fac.fact_sucursal = item.item_sucursal and fac.fact_numero = item.item_numero and fac.fact_tipo = item.item_tipo)
group by YEAR(fac.fact_fecha)
order by  YEAR(fac.fact_fecha)

----Opcion optimizada
select  
YEAR(fac.fact_fecha),
COUNT(distinct fac.fact_cliente) as clientes_diferentes,
COUNT(fac.fact_tipo+fac.fact_numero+fac.fact_sucursal) cantidad_facturas
from dbo.Factura fac 
inner join(
select item.item_numero, item.item_tipo, item_sucursal, SUM(item.item_cantidad * item.item_precio) as total 
from Item_Factura item  
group by item.item_numero, item.item_tipo, item_sucursal) total 
on total.item_tipo = fac.fact_tipo and total.item_sucursal =fac.fact_sucursal and total.item_numero = fac.fact_numero
where abs((fac.fact_total-fact_total_impuestos) - total.total) > 1 --Filtramos por la diferencia, el abs es para negativos incluirlos
group by YEAR(fac.fact_fecha)
--having (fac.fact_total-fact_total_impuestos) - total.total < 1

--
--22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
--trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
--por cada trimestre).
--Se deben mostrar 4 columnas:
-- Detalle del rubro
-- Numero de trimestre del año (1 a 4)
-- Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
--menos un producto del rubro
-- Cantidad de productos diferentes del rubro vendidos en el trimestre 

--El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
--rubro primero el trimestre en el que mas facturas se emitieron.
--No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
--no superen las 100.
--En ningun momento se tendran en cuenta los productos compuestos para esta
--estadistica

--Nota: 
--1)Debemos restar la fecha en 1, es mas comodo arrancar en cero.
--Se divide por 3 por trimestres 3*4 = 12 => 1 al 4, si divido por 4 =>1,2,3. Arranca en cero, por eso el +1
--2) Ojo con el orden, leer detalladamente, el segundo orden dice que muetre "primero el trimestre en el que mas facturas se emitieron"


select
ru.rubr_id,
(((MONTH(fac.fact_fecha)-1) / 3) + 1) as periodo, 
ru.rubr_detalle rubro_detalle, 
COUNT(distinct fac.fact_sucursal+fac.fact_tipo+fac.fact_numero) facturas_emitidas,
count(distinct item.item_producto) productos_diferentes
from Rubro ru 
inner join dbo.Producto prod on prod.prod_rubro = ru.rubr_id
inner join Item_Factura item on item.item_producto = prod.prod_codigo
inner join Factura fac on fac.fact_sucursal = item.item_sucursal and fac.fact_tipo = item.item_tipo and fac.fact_numero = item.item_numero
where item.item_producto not in (select comp_producto from Composicion)
group by ru.rubr_id,ru.rubr_detalle,(((MONTH(fac.fact_fecha)-1) / 3) + 1)
having COUNT(distinct fac.fact_sucursal+fac.fact_tipo+fac.fact_numero) > 100
order by 3,4 desc

--23. Realizar una consulta SQL que para cada año muestre :
-- Año
-- El producto con composición más vendido para ese año.
-- Cantidad de productos que componen directamente al producto más vendido
-- La cantidad de facturas en las cuales aparece ese producto.
-- El código de cliente que más compro ese producto.
-- El porcentaje que representa la venta de ese producto respecto al total de venta
--del año.
--El resultado deberá ser ordenado por el total vendido por año en forma descendente.


-----------------
--Gemini
SELECT 
    Ventas.anio,
    Ventas.item_producto AS [Producto mas vendido],
    (SELECT COUNT(*) FROM Composicion WHERE comp_producto = Ventas.item_producto) AS [Cant. Componentes],
    Ventas.cant_facturas AS [Facturas],
    (SELECT TOP 1 f2.fact_cliente 
     FROM Factura f2 
     JOIN Item_Factura i2 ON f2.fact_tipo = i2.item_tipo 
                          AND f2.fact_sucursal = i2.item_sucursal 
                          AND f2.fact_numero = i2.item_numero
     WHERE i2.item_producto = Ventas.item_producto AND YEAR(f2.fact_fecha) = Ventas.anio
     GROUP BY f2.fact_cliente 
     ORDER BY SUM(i2.item_cantidad) DESC) AS [Cliente mas Compras],
    (Ventas.total_vendido / TotalesAnio.TotalGral * 100) AS [Porcentaje]
FROM (
    -- 1. Calculamos ventas por año y producto (SOLO PRODUCTOS CON COMPOSICION)
    SELECT 
        YEAR(f.fact_fecha) anio, 
        i.item_producto, 
        SUM(i.item_cantidad) total_vendido, 
        COUNT(DISTINCT f.fact_tipo + f.fact_sucursal + f.fact_numero) cant_facturas
    FROM Factura f 
    JOIN Item_Factura i ON f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero
    WHERE i.item_producto IN (SELECT comp_producto FROM Composicion)
    GROUP BY YEAR(f.fact_fecha), i.item_producto
) AS Ventas
JOIN (
    -- 2. Buscamos el valor máximo vendido por cada año de los productos con composición
    SELECT anio, MAX(total_vendido) AS max_vendido
    FROM (
        SELECT YEAR(f.fact_fecha) anio, i.item_producto, SUM(i.item_cantidad) total_vendido
        FROM Factura f 
        JOIN Item_Factura i ON f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero
        WHERE i.item_producto IN (SELECT comp_producto FROM Composicion)
        GROUP BY YEAR(f.fact_fecha), i.item_producto
    ) AS aux 
    GROUP BY anio
) AS Maximos ON Ventas.anio = Maximos.anio AND Ventas.total_vendido = Maximos.max_vendido
JOIN (
    -- 3. Total de ventas de TODO el año (para el porcentaje)
    SELECT YEAR(fact_fecha) anio, SUM(item_cantidad) as TotalGral
    FROM Factura JOIN Item_Factura ON fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero
    GROUP BY YEAR(fact_fecha)
) AS TotalesAnio ON Ventas.anio = TotalesAnio.anio
ORDER BY Ventas.anio DESC;

-----------
--Utenianos
SELECT  YEAR(F.fact_fecha) 'Año',
		I.item_producto 'Producto mas vendido',
		(SELECT COUNT(*) FROM Composicion WHERE comp_producto = I.item_producto) 'Cant. Componentes',
		COUNT(DISTINCT F.fact_tipo + F.fact_sucursal + F.fact_numero) 'Facturas',
		(SELECT TOP 1 fact_cliente
		FROM Factura JOIN Item_Factura
			ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
		WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha) AND item_producto = I.item_producto
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC) 'Cliente mas Compras',
		SUM(ISNULL(I.item_cantidad, 0)) /
			(SELECT SUM(item_cantidad)
			FROM Factura JOIN Item_Factura
				ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
			WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha))*100 'Porcentaje'
FROM Factura F JOIN Item_Factura I
    ON (F.fact_tipo + F.fact_sucursal + F.fact_numero = I.item_tipo + I.item_sucursal + I.item_numero)
WHERE  I.item_producto = (SELECT TOP 1 item_producto
							   FROM Item_Factura
							   JOIN Composicion
							     ON item_producto = comp_producto
							   JOIN Factura
							     ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
							 WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
							 GROUP BY item_producto
							 ORDER BY SUM(item_cantidad) DESC)
GROUP BY YEAR(F.fact_fecha), I.item_producto
ORDER BY SUM(I.item_cantidad) DESC
--------

--Mio
select 
YEAR(fact.fact_fecha) as anio, 
prod.prod_codigo as codigo_producto, 
count(distinct comp.comp_componente) productos_componente,
COUNT(distinct fact.fact_sucursal+fact.fact_tipo+fact.fact_numero) cantidad_facturas
from Producto prod 
inner join Composicion comp on comp.comp_producto = prod.prod_codigo
inner join Item_Factura item on item.item_producto = prod_codigo
inner join Factura fact on fact.fact_numero = item.item_numero and fact.fact_sucursal = item.item_sucursal and fact.fact_tipo = item.item_tipo
where item_producto = (select i1.item_producto from Item_Factura i1 where i1.item_producto = item.item_producto
						group by i1.item_producto
						order by SUM(i1.item_precio * i1.item_cantidad) desc)
group by YEAR(fact.fact_fecha), prod.prod_codigo
order by 1

select i1.item_producto, YEAR(f1.fact_fecha), SUM(i1.item_precio * i1.item_cantidad) from Item_Factura i1 
inner join Factura f1 on  f1.fact_numero = i1.item_numero and f1.fact_sucursal = i1.item_sucursal and f1.fact_tipo = i1.item_tipo
inner join Composicion c1 on c1.comp_producto = i1.item_producto
where 
--i1.item_producto = item.item_producto and
YEAR(f1.fact_fecha) = 2012
group by i1.item_producto, YEAR(f1.fact_fecha)
order by i1.item_producto--,YEAR(f1.fact_fecha) 

select i1.item_producto , SUM(i1.item_cantidad) from Item_Factura i1 
inner join Factura f1 on  f1.fact_numero = i1.item_numero and f1.fact_sucursal = i1.item_sucursal and f1.fact_tipo = i1.item_tipo
inner join Composicion c1 on c1.comp_producto = i1.item_producto
where --i1.item_producto = '00001707' 
 Year(f1.fact_fecha) = 2012
group by i1.item_producto 


select SUM(i1.item_cantidad) from Item_Factura i1
inner join Factura f1 on  f1.fact_numero = i1.item_numero and f1.fact_sucursal = i1.item_sucursal and f1.fact_tipo = i1.item_tipo
where i1.item_producto = '00006402' and year(f1.fact_fecha) = 2012 

 SELECT 
        YEAR(f.fact_fecha) anio, 
        i.item_producto, 
        SUM(i.item_cantidad) total_vendido, 
        COUNT(DISTINCT f.fact_tipo + f.fact_sucursal + f.fact_numero) cant_facturas
    FROM Factura f 
    JOIN Item_Factura i ON f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero
    WHERE i.item_producto IN (SELECT comp_producto FROM Composicion)
    GROUP BY YEAR(f.fact_fecha), i.item_producto

select * from Composicion

------------------------Fin de guias en partes


/*2 fecha que lo tomaron, desconocida, solo se que es del 2021.
 
Realizar un stored procedure que reciba un código de producto y una fecha y devuelva la mayor cantidad de
días consecutivos a partir de esa fecha que el producto tuvo al menos la venta de una unidad en el día, el
sistema de ventas on line está habilitado 24-7 por lo que se deben evaluar todos los días incluyendo domingos y feriados.*/

alter procedure dbo.parcial_tssql_1(
@producto char(8),
@fecha datetime,
@max_dias_consecutivos int output
)
as 
BEGIN
	DECLARE @dias_consecutivos INT
	DECLARE @fecha_venta DATETIME
	DECLARE @fecha_anterior DATETIME

	SET @max_dias_consecutivos = 0    
    SET @dias_consecutivos = 0 
    SET @fecha_anterior = NULL

	DECLARE cVentasDelProducto CURSOR FOR

	SELECT CAST(fact_fecha AS DATE) -- <--- ACÁ
		FROM Factura 
		INNER JOIN Item_Factura 
		ON item_numero+item_tipo+item_sucursal = fact_numero+fact_tipo+fact_sucursal
	WHERE item_producto = @producto AND fact_fecha >= @fecha
	GROUP BY CAST(fact_fecha AS DATE) -- <--- Y ACÁ
	ORDER BY CAST(fact_fecha AS DATE) ASC;

	OPEN cVentasDelProducto

	FETCH NEXT FROM cVentasDelProducto INTO @fecha_venta

	WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Si es el primer registro que lee el cursor
        IF @fecha_anterior IS NULL
        BEGIN
            SET @dias_consecutivos = 1
        END
        -- Si la fecha actual es exactamente el día siguiente a la anterior
        ELSE IF (@fecha_venta = DATEADD(day, 1, @fecha_anterior))
        BEGIN
            SET @dias_consecutivos = @dias_consecutivos + 1
        END
        -- Si se rompió la racha consecutiva
        ELSE
        BEGIN
            IF (@dias_consecutivos > @max_dias_consecutivos)
            BEGIN
                SET @max_dias_consecutivos = @dias_consecutivos
            END
            SET @dias_consecutivos = 1 -- Empezamos una nueva racha en 1 con el día actual
        END
        
        SET @fecha_anterior = @fecha_venta
        FETCH NEXT FROM cVentasDelProducto INTO @fecha_venta
    END
	IF (@dias_consecutivos > @max_dias_consecutivos)
    BEGIN
        SET @max_dias_consecutivos = @dias_consecutivos
    END

    CLOSE cVentasDelProducto
    DEALLOCATE cVentasDelProducto

END;

-- 1. Declaramos una variable para recibir el resultado del procedimiento
DECLARE @RachaResultado INT;

-- 2. Ejecutamos el procedimiento pasándole los datos de prueba
EXEC dbo.parcial_tssql_1 
    @producto = '00001121',          -- Poné un código de producto que exista en tu tabla
    @fecha = '2012-01-01',           -- Fecha a partir de la cual querés empezar a evaluar
    @max_dias_consecutivos = @RachaResultado OUTPUT; -- ¡Clave poner OUTPUT acá también!

-- 3. Mostramos en pantalla el récord que calculó el cursor
SELECT @RachaResultado AS [Mayor Cantidad de Dias Consecutivos];

SELECT *
		FROM Factura 
		INNER JOIN Item_Factura 
		ON item_numero+item_tipo+item_sucursal = fact_numero+fact_tipo+fact_sucursal


---------------------------Guia ts sql inicio------------------------
/*1. Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.*/
create function dbo.Ejercicio1(
	@art char(8),
	@depo char(2)
)
Returns VARCHAR(100)
as
begin
	DECLARE @result DECIMAL(12,2);
	select @result = isnull((s.stoc_cantidad * 100)/s.stoc_stock_maximo,0) from STOCK s
	where s.stoc_producto = @art and s.stoc_deposito = @depo;
	return 
		case 
			when @result < 100 then
				'Ocupacion depo' + cast(@result as varchar(10))+ '%'
			else 'depo completo'
		end;
end;
go

select * from STOCK s where s.stoc_producto = '00000102' and s.stoc_deposito = '00';
SELECT dbo.Ejercicio1('00000102','00')

/*
/*2. Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha*/
*/

create function dbo.ejercicio2(
	@art varchar(8),
	@fecha date
)
returns decimal(12,2)
as
begin
	declare @stockActual decimal(12,2);
	declare @ventasPosteriores decimal(12,2);

    select @stockActual = isnull(SUM(s.stoc_cantidad),0) 
	from STOCK s where s.stoc_producto = @art
	
	select @ventasPosteriores  = isnull(SUM(item.item_cantidad),0) 
	from Item_Factura item inner join Factura fact 
	on fact.fact_tipo = item.item_tipo and fact.fact_sucursal = item.item_sucursal and fact.fact_numero = item.item_numero
	WHERE item.item_producto = @art and fact.fact_fecha > @fecha

	return @stockActual+@ventasPosteriores 
end;
/*
3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
de empleados que había sin jefe antes de la ejecución.



*/
/*4. Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.*/

alter proc ejercicio4(@EmplQueMasVendio numeric(6,0) OUTPUT)
AS
BEGIN
	declare @ultimoAnio int;
	select Top 1 @ultimoAnio = YEAR(fact_fecha) 
	from Factura 
	order by fact_fecha desc;
    
	SELECT top 1 @EmplQueMasVendio = f.fact_vendedor 
	FROM Factura f 
	where year(f.fact_fecha) =  @ultimoAnio 
	group by f.fact_vendedor 
	order by SUM(f.fact_total) desc;

	UPDATE Empleado SET empl_comision = 
	isnull((select SUM(f2.fact_total) from Factura f2 
	where year(f2.fact_fecha) = @ultimoAnio and f2.fact_vendedor = Empleado.empl_codigo), 0);
END;

--Prueba

BEGIN TRANSACTION; -- 1. Abrimos un "paréntesis" en el tiempo. Nada de lo que pase abajo será permanente.

    -- 2. Declaramos la variable externa
    DECLARE @EmplQueMasVendio_v NUMERIC(6,0);

    -- 3. Ejecutamos TU procedimiento (el UPDATE modificará la tabla temporalmente aquí adentro)
    EXEC ejercicio4 @EmplQueMasVendio = @EmplQueMasVendio_v OUTPUT;

    -- 4. Mostramos el vendedor top 1 devuelto por el parámetro OUTPUT
    SELECT @EmplQueMasVendio_v AS [Codigo del Vendedor Top 1];

   SELECT 'DESPUES' AS [Estado], empl_codigo, empl_nombre, empl_comision 
    FROM Empleado;

ROLLBACK TRANSACTION


/*
5. Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)

*/

-- 1. Borramos la tabla anterior si existe
DROP TABLE IF EXISTS Fact_table;

-- 2. La creamos con la restricción NOT NULL en la llave primaria
CREATE TABLE Fact_table (
    anio char(4) NOT NULL,
    mes char(2) NOT NULL,
    familia char(3) NOT NULL,
    rubro char(4) NOT NULL,
    zona char(3) NOT NULL,
    cliente char(6) NOT NULL,
    producto char(8) NOT NULL,
    cantidad decimal(12,2),
    monto decimal(12,2)
);

-- 3. Ahora sí, agregamos la Primary Key sin problemas
ALTER TABLE Fact_table
ADD CONSTRAINT PK_Fact_table_v2 PRIMARY KEY (anio, mes, familia, rubro, zona, cliente, producto);

create procedure dbo.ejercicio5
as
begin 
	truncate TABLE Fact_table;

	INSERT INTO Fact_table 
    (
        anio, mes, familia, rubro, zona, 
        cliente, producto, cantidad, monto
    )
	select
	YEAR(f1.fact_fecha),
	--month(f1.fact_fecha),
	---RIGHT('0' + CONVERT(VARCHAR(2), MONTH(f1.fact_fecha)), 2), --01,02.011. Siempre tomamos el de la derecha
	right('0'+(convert(varchar(2), month(f1.fact_fecha))),2) asd,
	p1.prod_familia,
	p1.prod_rubro,
	d1.depa_zona,
	f1.fact_cliente,
	p1.prod_codigo,
	SUM(i1.item_cantidad),
	SUM(i1.item_precio * i1.item_cantidad)
	from Producto p1 
	inner join Item_Factura i1 on p1.prod_codigo = i1.item_producto 
	inner join Factura f1 on f1.fact_tipo = i1.item_tipo and f1.fact_sucursal = i1.item_sucursal and i1.item_numero = f1.fact_numero 
	inner join Empleado e1 on f1.fact_vendedor = e1.empl_codigo
	inner join Departamento d1 on d1.depa_codigo = e1.empl_departamento
	group by 
	YEAR(f1.fact_fecha),
	--month(f1.fact_fecha),
	right('0'+(convert(varchar(2), month(f1.fact_fecha))),2),
	p1.prod_familia,
	p1.prod_rubro,
	d1.depa_zona,
	f1.fact_cliente,
	p1.prod_codigo
end;
--prueba
begin transaction
 exec dbo.ejercicio5;
 SELECT TOP 100 *  FROM Fact_table;
rollback transaction 

/*
6. Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deberá reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda.

*/

/*
7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.

*/
DROP TABLE Ventas;

CREATE TABLE Ventas (
    Codigo char(8) NOT NULL,                 -- O el tipo que tenga prod_codigo (ej: numeric, varchar, etc)
    Detalle char(50) NOT NULL,
    Cant_Mov INT NOT NULL,           -- Guardará el COUNT(*)
    precio_Venta DECIMAL(12,2) NOT NULL, -- Guardará el AVG(item_precio)
    Renglon INT NOT NULL,                -- Guardará el número de línea secuencial
    Ganancia DECIMAL(12,2) NOT NULL,     -- Guardará el cálculo final
    -- Opcional: Podrías poner una clave primaria si te lo piden, por ejemplo:
    --CONSTRAINT PK_Ventas PRIMARY KEY (Renglón)
);
GO
create procedure dbo.ejercicio7(
 @fechaDesde DATETIME,
 @fechaHasta DATETIME)
as
BEGIN
	truncate table Ventas;
	INSERT INTO Ventas (Codigo, Detalle, Cant_Mov, precio_Venta, Renglon, Ganancia)
	select 
	p1.prod_codigo Codigo,
	p1.prod_detalle Detalle,
	--p1.prod_precio,
	COUNT(i1.item_numero+i1.item_sucursal+i1.item_tipo) as Cant_Mov,
	--COUNT(*),
	AVG(i1.item_precio) as precio_Venta,
	ROW_NUMBER() OVER (ORDER BY p1.prod_codigo) AS Renglon,
	AVG(i1.item_precio) - (COUNT(*) * p1.prod_precio) as Ganancia
	from Producto p1 
	inner join Item_Factura i1 on i1.item_producto = p1.prod_codigo
	INNER JOIN Factura f1 on f1.fact_tipo = i1.item_tipo and f1.fact_sucursal = i1.item_sucursal and i1.item_numero = f1.fact_numero 
	WHERE f1.fact_fecha BETWEEN @fechaDesde AND @fechaHasta
	group by 
	p1.prod_codigo,
	p1.prod_detalle,
	p1.prod_precio
	--HAVING COUNT(i1.item_numero + i1.item_sucursal + i1.item_tipo) <> COUNT(*);
END;
--Prueba
begin transaction
	exec dbo.ejercicio7 '20120101', '20120228';
	SELECT * FROM Ventas

rollback transaction

/*
8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:


*/
drop table diferencias;

create table diferencias(
	Codigo char(8) NOT NULL,              
    Detalle char(50) NOT NULL,
	Cantidad INT NOT NULL,
	precio_generado decimal(12,2) NULL,
	precio_facturado decimal(12,2) NULL
	)


create function dbo.precio_compuesto(@producto char(8))
returns decimal(12,2)
as
begin 
 declare @precio decimal(12,2)
 select @precio = SUM(comp_cantidad* dbo.precio_compuesto(comp_componente)) from Composicion where comp_producto = @producto

 IF @Precio IS NULL
        -- Buscamos su precio directo en la lista de precios de la tabla Producto
        SET @Precio = (SELECT prod_precio FROM Producto WHERE prod_codigo = @producto)
 return @precio
end;

INSERT INTO Diferencias (Codigo, Detalle, Cantidad, Precio_generado, Precio_facturado)
select 
p1.prod_codigo,
p1.prod_detalle,
SUM(item1.item_cantidad) as cantidad,
dbo.precio_compuesto(p1.prod_codigo) as precio_generado,
item1.item_precio as precio_facturado
from Producto p1
inner join Item_Factura item1 on item1.item_producto = p1.prod_codigo
--inner join Factura fac1 on fac1.fact_sucursal = item1.item_sucursal and fac1.fact_tipo = item1.item_tipo and fac1.fact_numero = item1.item_numero
where p1.prod_codigo in (select distinct c1.comp_producto from Composicion c1)
group by p1.prod_codigo,
p1.prod_detalle, item_precio
having dbo.precio_compuesto(p1.prod_codigo) <> item1.item_precio

/*
10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.

*/

create trigger ejercicio10 ON Producto instead of delete
AS BEGIN
 IF EXISTS (SELECT 1 FROM STOCK S 
 INNER JOIN DELETED D ON S.stoc_producto = D.prod_codigo
 where S.stoc_cantidad > 0)
	BEGIN 
		RAISERROR ('No se puede borrar porque el artículo tiene stock.', 16, 1);
	END
 ELSE
	BEGIN
		DELETE FROM STOCK
		WHERE stoc_producto in (select D.prod_codigo from DELETED D)

		DELETE FROM Producto
		WHERE prod_codigo in (select D.prod_codigo from DELETED D)
	END
END;

-- 1. Abrimos la zona de pruebas segura
BEGIN TRANSACTION

	-- PRUEBA A: Intentar borrar el primer código
	-- Si este artículo tiene stock > 0, acá va a saltar el error en rojo del RAISERROR
	DELETE FROM Producto WHERE prod_codigo = '00006247'

	-- Miramos si sobrevivió o se borró (dentro de la transacción)
	SELECT * FROM Producto where prod_codigo = '00006247'


	-- PRUEBA B: Intentar borrar el segundo código
	-- Si este artículo NO tiene stock, el trigger lo va a borrar con éxito a él y a su stock
	--DELETE FROM Producto WHERE prod_codigo = '00006247'

	-- Miramos si se borró correctamente (debería venir vacío)
	--SELECT * FROM Producto where prod_codigo = '00006247'

-- 2. Deshacemos todo. El producto que se haya borrado en la Prueba B se recupera al instante.
ROLLBACK TRANSACTION

/*
12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.

*/

CREATE FUNCTION dbo.ejercicio12_EsComposicionCircular (
    @PadreBuscado char(8),
    @HijoActual char(8)
)
RETURNS BIT
AS
BEGIN
    -- CASO BASE: Si el hijo actual es igual al padre que estamos cuidando, hay un bucle.
    IF (@PadreBuscado = @HijoActual)
    BEGIN
        RETURN 1;
    END

    -- CASO RECURSIVO: Si el @HijoActual es a su vez un combo, revisamos sus componentes.
    -- Si alguna de las sub-llamadas recursivas devuelve 1, propagamos el 1 hacia arriba.
    IF EXISTS (
        SELECT 1 
        FROM Composicion
        WHERE comp_producto = @HijoActual
          AND dbo.EsComposicionCircular(@PadreBuscado, comp_componente) = 1
    )
    BEGIN
        RETURN 1;
    END

    -- Si revisó todos los caminos de este nodo y ninguno tocó al padre, está limpio.
    RETURN 0;
END;
GO

-----------------stop-------------------


------------------------Fin ts sql fin ---------------------