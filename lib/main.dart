import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(EncuentroAdapter());
  runApp(IntimiTrackApp());
}

class CamposFormulario {
  bool fecha;
  bool lugar;
  bool tipo;
  bool duracion;
  bool satisfaccion;
  bool notas;

  CamposFormulario({
    this.fecha = true,
    this.lugar = true,
    this.tipo = true,
    this.duracion = true,
    this.satisfaccion = true,
    this.notas = true,
  });

  Map<String, dynamic> toJson() => {
        'fecha': fecha,
        'lugar': lugar,
        'tipo': tipo,
        'duracion': duracion,
        'satisfaccion': satisfaccion,
        'notas': notas,
      };

  factory CamposFormulario.fromJson(Map<String, dynamic> json) =>
      CamposFormulario(
        fecha: json['fecha'] ?? true,
        lugar: json['lugar'] ?? true,
        tipo: json['tipo'] ?? true,
        duracion: json['duracion'] ?? true,
        satisfaccion: json['satisfaccion'] ?? true,
        notas: json['notas'] ?? true,
      );
}

class IntimiTrackApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoveStats',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DashboardPage(),
    );
  }
}

class Encuentro {
  final DateTime fecha;
  final String tipo;
  final String lugar;
  final Duration duracion;
  final int satisfaccion;
  final String notas;

  Encuentro({
    required this.fecha,
    required this.tipo,
    required this.lugar,
    required this.duracion,
    required this.satisfaccion,
    this.notas = '',
  });

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'tipo': tipo,
        'lugar': lugar,
        'duracion': duracion.inMinutes,
        'satisfaccion': satisfaccion,
        'notas': notas,
      };

  factory Encuentro.fromJson(Map<String, dynamic> json) => Encuentro(
        fecha: DateTime.parse(json['fecha']),
        tipo: json['tipo'],
        lugar: json['lugar'],
        duracion: Duration(minutes: json['duracion']),
        satisfaccion: json['satisfaccion'],
        notas: json['notas'] ?? '',
      );
}

enum VistaHeatmap { semana, mes, anyo }

enum TablaSeleccionada { duracion, satisfaccion }

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedChart = 'Ninguno';

  Widget _buildDuracionChart() {
    // Asegura que todos los minutos de 0 a 60 estén presentes
    Map<int, int> buckets = {for (var i = 0; i <= 60; i++) i: 0};
    for (var e in encuentros) {
      int minute = e.duracion.inMinutes;
      if (minute >= 0 && minute <= 60) {
        buckets[minute] = (buckets[minute] ?? 0) + 1;
      }
    }
    final allKeys = List<int>.generate(61, (i) => i);

    // Si no hay datos, maxY será 1 para mostrar el eje Y
    final maxY = buckets.values.any((v) => v > 0)
        ? (buckets.values.reduce((a, b) => a > b ? a : b) * 1.2).ceil()
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY.toDouble(),
              barTouchData: BarTouchData(enabled: false),
              gridData: FlGridData(show: false), // Sin líneas de fondo
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (maxY / 4).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value % (maxY / 4).ceil() != 0)
                        return Container();
                      return Text(value.toInt().toString(),
                          style: TextStyle(fontSize: 15));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5, // Solo muestra cada 10 minutos
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt();
                      if (idx < 0 || idx > 60 || idx % 5 != 0)
                        return Container();
                      return Text('$idx', style: TextStyle(fontSize: 15));
                    },
                  ),
                  axisNameWidget: Text('Duración'),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(allKeys.length, (i) {
                final key = allKeys[i];
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                      toY: buckets[key]!.toDouble(),
                      color: Colors.greenAccent,
                      width: 6),
                ]);
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSatisfaccionChart() {
    Map<int, int> counts = {for (var i = 1; i <= 5; i++) i: 0};
    for (var e in encuentros) {
      counts[e.satisfaccion] = (counts[e.satisfaccion] ?? 0) + 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: TextStyle(fontSize: 10));
                      }),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt() + 1;
                      if (idx < 1 || idx > 5) return Container();
                      return Text('$idx', style: TextStyle(fontSize: 10));
                    },
                  ),
                  axisNameWidget: Text('Satisfacción'),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(5, (i) {
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                      toY: counts[i + 1]!.toDouble(),
                      color: Colors.blueAccent,
                      width: 14),
                ]);
              }),
            ),
          ),
        ),
      ],
    );
  }

  List<Encuentro> encuentros = [];
  VistaHeatmap _vista = VistaHeatmap.anyo;
  DateTime _fechaReferencia = DateTime.now();
  TablaSeleccionada _tablaSeleccionada = TablaSeleccionada.duracion;

  @override
  void initState() {
    super.initState();
    _cargarEncuentros().then((lista) {
      setState(() {
        encuentros = lista;
      });
    });
    cargarPreferenciasCampos().then((_) {
      setState(() {});
    });
  }

  Future<void> _guardarEncuentros(List<Encuentro> encuentros) async {
    final box = await Hive.openBox<Encuentro>('encuentros');
    await box.clear();
    await box.addAll(encuentros);
  }

  Future<List<Encuentro>> _cargarEncuentros() async {
    final box = await Hive.openBox<Encuentro>('encuentros');
    return box.values.toList();
  }

  void _agregarEncuentro(Encuentro nuevo) async {
    setState(() {
      encuentros.add(nuevo);
    });
    await _guardarEncuentros(encuentros);
  }

  int _calcularStreak() {
    if (encuentros.isEmpty) return 0;

    final fechas = encuentros.map((e) => DateUtils.dateOnly(e.fecha)).toSet();
    final hoy = DateUtils.dateOnly(DateTime.now());
    int streak = 0;

    // Si hay registro hoy o ayer, calcula la racha positiva
    for (int i = 0;; i++) {
      final dia = hoy.subtract(Duration(days: i));
      if (fechas.contains(dia)) {
        streak++;
      } else {
        if (i == 0) continue; // hoy no cuenta
        if (streak > 0) break;
        // Si no hay racha positiva, calcula días desde el último registro
        final ultimo = fechas.reduce((a, b) => a.isAfter(b) ? a : b);
        final diasSinRegistro = hoy.difference(ultimo).inDays;
        return -diasSinRegistro;
      }
    }

    return streak;
  }

  void _cambiarVista(VistaHeatmap nuevaVista) {
    setState(() {
      _vista = nuevaVista;
      _fechaReferencia = DateTime.now();
    });
  }

  void _moverFecha(int pasos) {
    setState(() {
      switch (_vista) {
        case VistaHeatmap.semana:
          _fechaReferencia = _fechaReferencia.add(Duration(days: pasos * 7));
          break;
        case VistaHeatmap.mes:
          _fechaReferencia = DateTime(
            _fechaReferencia.year,
            _fechaReferencia.month + pasos,
            1,
          );
          break;
        case VistaHeatmap.anyo:
          _fechaReferencia = DateTime(
            _fechaReferencia.year + pasos,
            1,
            1,
          );
          break;
      }
    });
  }

  Widget _buildHeatMap() {
    Map<String, int> conteoPorDia = {};
    for (var e in encuentros) {
      final key = DateFormat('yyyy-MM-dd').format(e.fecha);
      conteoPorDia[key] = (conteoPorDia[key] ?? 0) + 1;
    }

    int totalDias;
    DateTime inicio;
    switch (_vista) {
      case VistaHeatmap.semana:
        totalDias = 7;
        inicio = _fechaReferencia
            .subtract(Duration(days: _fechaReferencia.weekday - 1));
        break;
      case VistaHeatmap.mes:
        totalDias = DateUtils.getDaysInMonth(
            _fechaReferencia.year, _fechaReferencia.month);
        inicio = DateTime(_fechaReferencia.year, _fechaReferencia.month, 1);
        break;
      case VistaHeatmap.anyo:
        totalDias = 365;
        inicio = DateTime(_fechaReferencia.year, 1, 1);
        break;
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(totalDias, (index) {
        final dia = inicio.add(Duration(days: index));
        final key = DateFormat('yyyy-MM-dd').format(dia);
        final count = conteoPorDia[key] ?? 0;
        Color color;
        if (count == 0)
          color = Colors.grey[200]!;
        else if (count == 1)
          color = Colors.green[300]!;
        else if (count == 2)
          color = Colors.green[600]!;
        else
          color = Colors.green[900]!;

        return Tooltip(
          message: DateFormat('dd/MM/yyyy').format(dia) + ' ($count)',
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTablaEncuentros() {
    List<DataRow> filas;

    switch (_tablaSeleccionada) {
      case TablaSeleccionada.duracion:
        filas = encuentros.map((e) {
          return DataRow(cells: [
            DataCell(Text(DateFormat('dd/MM').format(e.fecha))),
            DataCell(Text('${e.duracion.inMinutes} min')),
            DataCell(Text(e.tipo)),
          ]);
        }).toList();
        break;
      case TablaSeleccionada.satisfaccion:
        filas = encuentros.map((e) {
          return DataRow(cells: [
            DataCell(Text(DateFormat('dd/MM').format(e.fecha))),
            DataCell(Text(e.satisfaccion.toString())),
            DataCell(Text(e.tipo)),
          ]);
        }).toList();
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<TablaSeleccionada>(
          value: _tablaSeleccionada,
          onChanged: (nueva) {
            if (nueva != null) {
              setState(() => _tablaSeleccionada = nueva);
            }
          },
          items: [
            DropdownMenuItem(
                value: TablaSeleccionada.duracion,
                child: Text('Duración de encuentros')),
            DropdownMenuItem(
                value: TablaSeleccionada.satisfaccion,
                child: Text('Satisfacción de encuentros')),
          ],
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Fecha')),
              if (_tablaSeleccionada == TablaSeleccionada.duracion)
                DataColumn(label: Text('Duración'))
              else
                DataColumn(label: Text('Satisfacción')),
              DataColumn(label: Text('Tipo')),
            ],
            rows: filas,
          ),
        ),
      ],
    );
  }

  void _abrirFormulario() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormularioEncuentro()),
    );
    if (resultado != null && resultado is Encuentro) {
      _agregarEncuentro(resultado);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final racha = _calcularStreak();
    final esNegativa = racha < 0;

    Widget? chartWidget;
    if (_selectedChart == 'Duración') {
      chartWidget = _buildDuracionChart();
    } else if (_selectedChart == 'Satisfacción') {
      chartWidget = _buildSatisfaccionChart();
    } else {
      chartWidget = null;
    }

    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: Text('LoveStats'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => HistoricoEncuentros(
                  encuentros: encuentros,
                  campos: camposActivos,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfiguracionCamposPage(camposActivos),
                ),
              );
              if (resultado != null && resultado is CamposFormulario) {
                setState(() {
                  camposActivos = resultado;
                });
                guardarPreferenciasCampos();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left),
                            onPressed: () => _moverFecha(-1),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right),
                            onPressed: () => _moverFecha(1),
                          ),
                        ],
                      ),
                      DropdownButton<VistaHeatmap>(
                        value: _vista,
                        onChanged: (vista) {
                          if (vista != null) _cambiarVista(vista);
                        },
                        items: [
                          DropdownMenuItem(
                              value: VistaHeatmap.semana,
                              child: Text('Semana')),
                          DropdownMenuItem(
                              value: VistaHeatmap.mes, child: Text('Mes')),
                          DropdownMenuItem(
                              value: VistaHeatmap.anyo, child: Text('Año')),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${esNegativa ? "❄️ Racha rota" : "🔥 Streak actual"}: ${racha.abs()} días',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  _buildHeatMap(),
                  SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _selectedChart,
                    items: [
                      DropdownMenuItem(value: 'Ninguno', child: Text(' ')),
                      DropdownMenuItem(
                          value: 'Duración', child: Text('Duración')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedChart = val!;
                      });
                    },
                  ),
                  if (chartWidget != null) ...[
                    SizedBox(height: 20),
                    chartWidget,
                  ],
                  SizedBox(height: 20),
                  Text('📊 Total encuentros: ${encuentros.length}',
                      style: TextStyle(fontSize: 16)),
                  // Removed tables below the charts
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        child: Icon(Icons.add),
      ),
    );
  }
}

class FormularioEncuentro extends StatefulWidget {
  @override
  _FormularioEncuentroState createState() => _FormularioEncuentroState();
}

class _FormularioEncuentroState extends State<FormularioEncuentro> {
  final _formKey = GlobalKey<FormState>();
  DateTime _fecha = DateTime.now();
  String _tipo = 'Penetración';
  String _lugar = '';
  int _duracionMin = 10;
  int _satisfaccion = 3;
  String _notas = '';

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (fechaSeleccionada != null) {
      setState(() {
        _fecha = fechaSeleccionada;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo encuentro'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfiguracionCamposPage(camposActivos),
                ),
              );
              if (resultado != null && resultado is CamposFormulario) {
                setState(() {
                  camposActivos = resultado;
                });
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (camposActivos.fecha)
                ListTile(
                  title:
                      Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_fecha)}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _seleccionarFecha(context),
                ),
              if (camposActivos.lugar)
                TextFormField(
                  decoration: InputDecoration(labelText: 'Lugar'),
                  onChanged: (val) => _lugar = val,
                ),
              if (camposActivos.tipo)
                DropdownButtonFormField<String>(
                  value: _tipo,
                  items: ['Penetración', 'Oral', 'Beso', 'Otro']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => _tipo = val!,
                  decoration: InputDecoration(labelText: 'Tipo'),
                ),
              if (camposActivos.duracion)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text('Duración (min): $_duracionMin'),
                    Slider(
                      value: _duracionMin.toDouble(),
                      min: 0,
                      max: 60,
                      divisions: 60,
                      label: '$_duracionMin min',
                      onChanged: (val) =>
                          setState(() => _duracionMin = val.toInt()),
                    ),
                  ],
                ),
              if (camposActivos.satisfaccion)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text('Satisfacción: $_satisfaccion'),
                    Slider(
                      value: _satisfaccion.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$_satisfaccion',
                      onChanged: (val) =>
                          setState(() => _satisfaccion = val.toInt()),
                    ),
                  ],
                ),
              if (camposActivos.notas)
                TextFormField(
                  decoration: InputDecoration(labelText: 'Notas'),
                  onChanged: (val) => _notas = val,
                  maxLines: 3,
                ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.check),
                label: Text('Guardar'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      Encuentro(
                        fecha: _fecha,
                        tipo: _tipo,
                        lugar: _lugar,
                        duracion: Duration(minutes: _duracionMin),
                        satisfaccion: _satisfaccion,
                        notas: _notas,
                      ),
                    );
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ConfiguracionCamposPage extends StatefulWidget {
  final CamposFormulario campos;
  ConfiguracionCamposPage(this.campos);

  @override
  _ConfiguracionCamposPageState createState() =>
      _ConfiguracionCamposPageState();
}

class _ConfiguracionCamposPageState extends State<ConfiguracionCamposPage> {
  late CamposFormulario campos;

  @override
  void initState() {
    super.initState();
    campos = CamposFormulario(
      fecha: widget.campos.fecha,
      lugar: widget.campos.lugar,
      tipo: widget.campos.tipo,
      duracion: widget.campos.duracion,
      satisfaccion: widget.campos.satisfaccion,
      notas: widget.campos.notas,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configurar campos')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Fecha'),
            value: campos.fecha,
            onChanged: (v) => setState(() => campos.fecha = v),
          ),
          SwitchListTile(
            title: Text('Lugar'),
            value: campos.lugar,
            onChanged: (v) => setState(() => campos.lugar = v),
          ),
          SwitchListTile(
            title: Text('Tipo'),
            value: campos.tipo,
            onChanged: (v) => setState(() => campos.tipo = v),
          ),
          SwitchListTile(
            title: Text('Duración'),
            value: campos.duracion,
            onChanged: (v) => setState(() => campos.duracion = v),
          ),
          SwitchListTile(
            title: Text('Satisfacción'),
            value: campos.satisfaccion,
            onChanged: (v) => setState(() => campos.satisfaccion = v),
          ),
          SwitchListTile(
            title: Text('Notas'),
            value: campos.notas,
            onChanged: (v) => setState(() => campos.notas = v),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            child: Text('Guardar'),
            onPressed: () {
              Navigator.pop(context, campos);
              camposActivos = campos;
              guardarPreferenciasCampos();
            },
          )
        ],
      ),
    );
  }
}

class HistoricoEncuentros extends StatelessWidget {
  final List<Encuentro> encuentros;
  final CamposFormulario campos;

  const HistoricoEncuentros({
    required this.encuentros,
    required this.campos,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: [
                if (campos.fecha) DataColumn(label: Text('Fecha')),
                if (campos.lugar) DataColumn(label: Text('Lugar')),
                if (campos.tipo) DataColumn(label: Text('Tipo')),
                if (campos.duracion) DataColumn(label: Text('Duración')),
                if (campos.satisfaccion)
                  DataColumn(label: Text('Satisfacción')),
                if (campos.notas) DataColumn(label: Text('Notas')),
              ],
              rows: encuentros.map((e) {
                return DataRow(cells: [
                  if (campos.fecha)
                    DataCell(Text(DateFormat('dd/MM/yyyy').format(e.fecha))),
                  if (campos.lugar) DataCell(Text(e.lugar)),
                  if (campos.tipo) DataCell(Text(e.tipo)),
                  if (campos.duracion)
                    DataCell(Text(
                      (e.duracion != null && e.duracion.inMinutes >= 0)
                          ? '${e.duracion.inMinutes} min'
                          : '-',
                    )),
                  if (campos.satisfaccion)
                    DataCell(Text(e.satisfaccion.toString())),
                  if (campos.notas) DataCell(Text(e.notas)),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// --- HIVE ADAPTER PARA ENCUENTRO ---
class EncuentroAdapter extends TypeAdapter<Encuentro> {
  @override
  final int typeId = 0;

  @override
  Encuentro read(BinaryReader reader) {
    return Encuentro(
      fecha: DateTime.parse(reader.readString()),
      tipo: reader.readString(),
      lugar: reader.readString(),
      duracion: Duration(minutes: reader.readInt()),
      satisfaccion: reader.readInt(),
      notas: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Encuentro obj) {
    writer.writeString(obj.fecha.toIso8601String());
    writer.writeString(obj.tipo);
    writer.writeString(obj.lugar);
    writer.writeInt(obj.duracion.inMinutes);
    writer.writeInt(obj.satisfaccion);
    writer.writeString(obj.notas);
  }
}

// --- CAMPOS Y FUNCIONES DE PREFERENCIAS CON HIVE ---
CamposFormulario camposActivos = CamposFormulario();

Future<void> guardarPreferenciasCampos() async {
  final box = await Hive.openBox('preferencias');
  await box.put('camposActivos', camposActivos.toJson());
}

Future<void> cargarPreferenciasCampos() async {
  final box = await Hive.openBox('preferencias');
  final data = box.get('camposActivos');
  if (data != null) {
    camposActivos = CamposFormulario.fromJson(Map<String, dynamic>.from(data));
  }
}
