insert into innova_pramos.ventasdetalle (idventadetalle,idventa,idproducto,descripcion,idmedida,
    factor,cantidadfactor,cantidad,preciolista,precioventa,
    idbodega,totalgravado,totaliva,costopromedio,entradasalida,modulo,tipoiva) 
SELECT a.iddoctod,a.iddocto,c.idproducto,a.producto,ifnull(d.idtipodocumento,0),a.factor,a.cantiunimed,a.cantidad,
   a.preciosiniva,a.preciosinivaunidad,1,a.totalgravado,a.totaliva,a.costounimed,a.entsal,'VE',c.tipoiva
   FROM innova_agils_pramos1.cyvventasdeta a  
		inner join innova_agils_pramos1.invproductos b on a.idproducto=b.idproducto
        inner join innova_pramos.productos c on if(ifnull(b.codprod3,'')='',b.codprod,b.codprod3)=c.codproducto
        left join  innova_pramos.tipocambio d on a.unimed=d.medida and d.origen='MED'and b.unidadmedida<>a.unimed 
	where a.iddoctod not in (select idventa from innova_pramos.ventas) and a.iddocto in 
			(select a.iddocto from innova_agils_pramos1.cyvventas a
            inner join innova_pramos.tipocambio b on a.idtipodocto=b.idtipodocto and b.origen='TPD'
            inner join innova_pramos.tipocambio c on a.idserie=c.idtipodocto and c.origen='SER'
            inner join innova_agils_pramos1.cyvclipro d on a.idclipro=d.idclipro
            left join innova_pramos.socionegocios e on d.codclipro=e.codsocionegocio
            left join innova_agils_pramos1.siscata f on a.iddepto=f.id and f.origen='DEP'
            left join innova_agils_pramos1.siscata g on a.idagente=g.id and g.origen='VEN'
            where a.fechadocto='2019-06-03') order by a.iddoctod
