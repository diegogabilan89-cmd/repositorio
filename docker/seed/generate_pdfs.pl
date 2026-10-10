#!/usr/bin/perl
# =============================================================================
#  Genera los 3 PDF de prueba del repositorio (contenido FICTICIO).
#
#  No necesita módulos externos: escribe el PDF "a mano" con la fuente estándar
#  Helvetica (codificación WinAnsi, admite tildes y ñ).
#
#  Uso:   perl docker/seed/generate_pdfs.pl  [carpeta_destino]
#         (por defecto: docker/seed/pdfs)
# =============================================================================
use strict;
use warnings;
use utf8;
use Encode qw(encode);
use File::Basename qw(dirname);
use File::Spec;

my $outdir = shift @ARGV || File::Spec->catdir( dirname( __FILE__ ), 'pdfs' );
mkdir $outdir unless -d $outdir;

my $AVISO = 'DOCUMENTO DE PRUEBA — Contenido ficticio elaborado con fines académicos para validar el '
          . 'Repositorio Digital del Hospital General de Itapúa. Los autores, datos y resultados son simulados.';

my @DOCS = (
{
	file     => 'investigacion_prevalencia_hipertension_2025.pdf',
	kind     => 'ARTÍCULO DE INVESTIGACIÓN',
	title    => 'Prevalencia de hipertensión arterial y factores de riesgo asociados en pacientes adultos de consultorio externo',
	authors  => 'Ana Lucía Martínez; Carlos Andrés Ramírez',
	affil    => 'Servicio de Medicina Interna — Hospital General de Itapúa',
	date     => 'Noviembre de 2025',
	sections => [
		[ 'Resumen', 'Objetivo: estimar la prevalencia de hipertensión arterial (HTA) y describir los factores de riesgo asociados en adultos atendidos en consultorio externo. Métodos: estudio observacional, descriptivo y de corte transversal con una muestra simulada de 412 pacientes. Resultados: la prevalencia estimada de HTA fue del 34,2 %; la obesidad, el sedentarismo y el antecedente familiar se asociaron con mayor frecuencia de HTA. Conclusión: los datos ficticios ilustran la importancia del tamizaje sistemático de la presión arterial en la consulta ambulatoria.' ],
		[ 'Introducción', 'La hipertensión arterial es uno de los principales factores de riesgo cardiovascular modificables. Conocer su frecuencia en la población atendida permite planificar estrategias de prevención, diagnóstico oportuno y seguimiento en los servicios de salud.' ],
		[ 'Métodos', 'Diseño observacional, descriptivo y transversal. Población: pacientes de 18 años o más que acudieron a consultorio externo durante un período de seis meses (datos simulados). Variables: presión arterial, índice de masa corporal, actividad física, tabaquismo y antecedentes familiares. Se calcularon frecuencias absolutas y relativas, y razones de prevalencia con intervalos de confianza del 95 %.' ],
		[ 'Resultados (simulados)', 'De los 412 pacientes incluidos, 141 presentaron cifras compatibles con HTA (34,2 %). La frecuencia fue mayor en mayores de 60 años y en pacientes con obesidad. El 58 % de los pacientes con HTA desconocía su diagnóstico antes de la consulta.' ],
		[ 'Conclusiones', 'En este ejercicio ficticio, uno de cada tres adultos presentó HTA y más de la mitad desconocía su condición. Se recomienda reforzar la medición rutinaria de la presión arterial y la educación sobre estilos de vida saludables.' ],
		[ 'Palabras clave', 'hipertensión arterial; prevalencia; factores de riesgo; atención ambulatoria.' ],
	],
},
{
	file     => 'tesis_adherencia_lactancia_materna.pdf',
	kind     => 'TESIS DE ESPECIALIZACIÓN',
	title    => 'Factores asociados a la adherencia a la lactancia materna exclusiva en puérperas atendidas en el Servicio de Pediatría',
	authors  => 'Laura Beatriz Gómez',
	affil    => 'Tesis presentada para optar al título de Especialista en Pediatría — Residencia Médica, Hospital General de Itapúa',
	date     => 'Febrero de 2026',
	sections => [
		[ 'Resumen', 'La lactancia materna exclusiva durante los primeros seis meses de vida aporta beneficios para la salud del lactante y de la madre. Esta tesis ficticia plantea un estudio analítico para identificar factores sociodemográficos, obstétricos y de atención sanitaria asociados a la adherencia a la lactancia materna exclusiva.' ],
		[ 'Planteamiento del problema', 'A pesar de las recomendaciones internacionales, una proporción importante de madres abandona la lactancia materna exclusiva antes de los seis meses. Identificar los factores asociados permite diseñar intervenciones de apoyo más eficaces desde el control prenatal y el seguimiento pediátrico.' ],
		[ 'Objetivos', 'General: determinar los factores asociados a la adherencia a la lactancia materna exclusiva. Específicos: describir las características sociodemográficas de las puérperas; estimar la proporción de adherencia al primer, tercer y sexto mes; y analizar la asociación con la consejería recibida, el tipo de parto y el retorno laboral.' ],
		[ 'Metodología', 'Estudio observacional, analítico, de cohorte prospectiva (diseño propuesto). Población: puérperas atendidas en el Servicio de Pediatría durante doce meses. Instrumento: cuestionario estructurado aplicado en los controles de salud. Análisis: estadística descriptiva y regresión logística para estimar razones de ventaja ajustadas.' ],
		[ 'Resultados esperados', 'Se espera que la consejería en lactancia durante el control prenatal y el apoyo familiar se asocien con mayor adherencia, mientras que el retorno temprano al trabajo y el parto por cesárea se asocien con abandono precoz.' ],
		[ 'Conclusiones', 'Este documento ficticio sirve como ejemplo de tesis de especialización para validar la carga, descripción y búsqueda de documentos en el repositorio institucional.' ],
	],
},
{
	file     => 'guia_manejo_inicial_sepsis_urgencias.pdf',
	kind     => 'GUÍA DE PRÁCTICA CLÍNICA',
	title    => 'Reconocimiento y manejo inicial de la sepsis en el Servicio de Urgencias',
	authors  => 'Ricardo Villalba; María José Benítez',
	affil    => 'Servicio de Urgencias y Unidad de Terapia Intensiva — Hospital General de Itapúa',
	date     => 'Mayo de 2026 — Versión de prueba 0.1',
	sections => [
		[ 'Advertencia', 'Esta guía es un DOCUMENTO DE PRUEBA creado para validar el repositorio. Resume conceptos generales y NO debe utilizarse para tomar decisiones clínicas. Para la atención de pacientes deben seguirse los protocolos institucionales vigentes.' ],
		[ 'Alcance y población', 'Dirigida al personal médico y de enfermería del Servicio de Urgencias. Población: pacientes adultos con sospecha de infección y signos de disfunción orgánica.' ],
		[ 'Reconocimiento temprano', 'Aplicar una herramienta de tamizaje validada en el triaje a todo paciente con sospecha de infección. Valorar signos vitales, estado de conciencia, perfusión periférica y diuresis. Ante sospecha de sepsis, activar el circuito de atención prioritaria.' ],
		[ 'Evaluación inicial', 'Solicitar estudios de laboratorio según protocolo, incluyendo lactato cuando esté disponible. Obtener muestras para cultivo antes de iniciar antimicrobianos, siempre que ello no retrase el tratamiento. Buscar el foco infeccioso.' ],
		[ 'Tratamiento inicial', 'Iniciar tratamiento antimicrobiano empírico de forma precoz, según el protocolo institucional y el foco sospechado. Indicar reanimación hemodinámica guiada por la evaluación clínica. Considerar soporte vasopresor e interconsulta con la Unidad de Terapia Intensiva ante hipotensión persistente.' ],
		[ 'Reevaluación y seguimiento', 'Reevaluar al paciente de forma frecuente durante las primeras horas: respuesta hemodinámica, perfusión, diuresis y evolución de los parámetros de laboratorio. Ajustar el tratamiento según los resultados de los cultivos y documentar todas las intervenciones.' ],
		[ 'Indicadores sugeridos', 'Proporción de pacientes con tamizaje en el triaje; tiempo hasta la primera dosis de antimicrobiano; proporción de pacientes con cultivos tomados antes del tratamiento.' ],
	],
},
);

foreach my $doc ( @DOCS )
{
	my $pdf = build_pdf( $doc );
	my $path = File::Spec->catfile( $outdir, $doc->{file} );
	open( my $fh, '>:raw', $path ) or die "No se pudo escribir $path: $!\n";
	print $fh $pdf;
	close $fh;
	printf "Generado %s (%d bytes)\n", $path, length $pdf;
}

# -----------------------------------------------------------------------------
#  Maquetación sencilla: A4, márgenes de 60 pt, texto con ajuste de línea
# -----------------------------------------------------------------------------
sub build_pdf
{
	my( $doc ) = @_;
	my( $W, $H, $M ) = ( 595, 842, 60 );
	my @pages;
	my $ops = '';
	my $y = $H - $M;

	my $new_page = sub {
		push @pages, $ops if length $ops;
		$ops = '';
		$y = $H - $M;
		# Banda superior con el aviso de documento de prueba
		$ops .= "0.80 0.10 0.10 rg 0 " . ( $H - 28 ) . " $W 28 re f\n";
		$ops .= text_op( 'F2', 9, $M, $H - 18, 'DOCUMENTO DE PRUEBA — CONTENIDO FICTICIO', [1,1,1] );
		$ops .= text_op( 'F1', 8, $W - $M - 150, 30, 'Repositorio Digital — HGI', [0.4,0.4,0.4] );
		$y -= 20;
	};
	my $write = sub {
		my( $font, $size, $text, $gap, $color ) = @_;
		foreach my $line ( wrap( $text, $size, $W - 2 * $M ) )
		{
			$new_page->() if $y < $M + $size;
			$ops .= text_op( $font, $size, $M, $y, $line, $color );
			$y -= $size * 1.35;
		}
		$y -= $gap // 0;
	};

	$new_page->();
	$write->( 'F2', 10, $doc->{kind}, 6, [0.10,0.35,0.55] );
	$write->( 'F2', 17, $doc->{title}, 8 );
	$write->( 'F1', 11, $doc->{authors}, 2 );
	$write->( 'F1', 9,  $doc->{affil}, 2, [0.3,0.3,0.3] );
	$write->( 'F1', 9,  $doc->{date}, 10, [0.3,0.3,0.3] );
	$ops .= "0.75 0.75 0.75 RG 0.8 w $M $y m " . ( $W - $M ) . " $y l S\n";
	$y -= 16;
	$write->( 'F3', 9, $AVISO, 12, [0.6,0.1,0.1] );
	foreach my $s ( @{ $doc->{sections} } )
	{
		$write->( 'F2', 12, $s->[0], 3, [0.10,0.35,0.55] );
		$write->( 'F1', 10.5, $s->[1], 10 );
	}
	push @pages, $ops;

	# --- Objetos PDF ---
	my @obj;
	my $n_pages = scalar @pages;
	my $first_page = 7;                      # 1-6: catálogo, páginas, fuentes, info
	my @kids = map { ( $first_page + 2 * $_ ) . ' 0 R' } 0 .. $n_pages - 1;
	$obj[1] = '<< /Type /Catalog /Pages 2 0 R /Lang (es-PY) >>';
	$obj[2] = "<< /Type /Pages /Count $n_pages /Kids [ @kids ] >>";
	$obj[3] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>';
	$obj[4] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>';
	$obj[5] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique /Encoding /WinAnsiEncoding >>';
	$obj[6] = '<< /Title (' . pdf_str( $doc->{title} ) . ') /Author (' . pdf_str( $doc->{authors} ) . ')'
	        . ' /Subject (' . pdf_str( $doc->{kind} . ' - documento de prueba' ) . ')'
	        . ' /Creator (generate_pdfs.pl) /Producer (Repositorio Digital HGI) /CreationDate (D:20261009000000) >>';
	for my $i ( 0 .. $n_pages - 1 )
	{
		my $p = $first_page + 2 * $i;
		my $stream = encode( 'cp1252', $pages[$i] );
		$obj[$p] = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $W $H]"
		         . ' /Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >>'
		         . ' /Contents ' . ( $p + 1 ) . ' 0 R >>';
		$obj[$p + 1] = '<< /Length ' . length( $stream ) . " >>\nstream\n" . $stream . "\nendstream";
	}

	my $out = "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";
	my @offsets;
	for my $i ( 1 .. $#obj )
	{
		$offsets[$i] = length $out;
		my $body = $obj[$i];
		$body = encode( 'cp1252', $body ) if utf8::is_utf8( $body );
		$out .= "$i 0 obj\n$body\nendobj\n";
	}
	my $xref = length $out;
	$out .= "xref\n0 " . ( $#obj + 1 ) . "\n0000000000 65535 f \n";
	$out .= sprintf( "%010d 00000 n \n", $offsets[$_] ) for 1 .. $#obj;
	$out .= "trailer\n<< /Size " . ( $#obj + 1 ) . " /Root 1 0 R /Info 6 0 R >>\nstartxref\n$xref\n%%EOF\n";
	return $out;
}

sub text_op
{
	my( $font, $size, $x, $y, $text, $color ) = @_;
	my $c = $color ? sprintf( '%.2f %.2f %.2f rg ', @$color ) : '0 0 0 rg ';
	return sprintf( "BT %s/%s %s Tf %.1f %.1f Td (%s) Tj ET\n", $c, $font, $size, $x, $y, pdf_str( $text ) );
}

sub pdf_str
{
	my( $s ) = @_;
	$s =~ s/([\\()])/\\$1/g;
	return $s;
}

# Ajuste de línea aproximado (ancho medio de Helvetica ≈ 0,5 em)
sub wrap
{
	my( $text, $size, $width ) = @_;
	my $max = int( $width / ( $size * 0.5 ) );
	my( @lines, $cur );
	foreach my $word ( split /\s+/, $text )
	{
		if( !defined $cur ) { $cur = $word; next; }
		if( length( $cur ) + 1 + length( $word ) > $max ) { push @lines, $cur; $cur = $word; }
		else { $cur .= " $word"; }
	}
	push @lines, $cur if defined $cur;
	return @lines;
}
