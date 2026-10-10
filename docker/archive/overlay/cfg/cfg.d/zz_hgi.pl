######################################################################
#
#  Personalización del Repositorio Digital del Hospital General de Itapúa
#
#  Este archivo se copia al repositorio la primera vez que se crea
#  (archives/<ARCHIVE_ID>/cfg/cfg.d/zz_hgi.pl). Para aplicar cambios
#  posteriores: editarlo dentro del volumen y reiniciar el contenedor.
#
######################################################################

# Valores por defecto de cada documento (archivo) subido: idioma español
# y acceso público. Reemplaza al disparador 'core_document_defaults'.
$c->add_dataset_trigger( 'document', EP_TRIGGER_DEFAULTS, sub {
	my( %params ) = @_;
	my $data = $params{data};
	$data->{language} = 'es';
	$data->{security} = 'public';
}, id => 'core_document_defaults' );

# Tamaño máximo de subida de archivos (200 MB). EPrints traslada este valor
# a la configuración de Apache (LimitRequestBody) al regenerarla.
$c->{max_upload_filesize} = 200 * 1024 * 1024;
