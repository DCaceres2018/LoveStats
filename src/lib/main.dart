import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(IntimiTrackApp());
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
    // Agrupa duraciones en intervalos de 10 minutos
    Map<int, int> buckets = {};
    for (var e in encuentros) {
      int bucket = (e.duracion.inMinutes / 10).floor() * 10;
      buckets[bucket] = (buckets[bucket] ?? 0) + 1;
    }
    final sortedKeys = buckets.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duración (min) vs. Cantidad',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                      int idx = value.toInt();
                      if (idx < 0 || idx >= sortedKeys.length)
                        return Container();
                      return Text('${sortedKeys[idx]}',
                          style: TextStyle(fontSize: 10));
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
              barGroups: List.generate(sortedKeys.length, (i) {
                final key = sortedKeys[i];
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                      toY: buckets[key]!.toDouble(),
                      color: Colors.greenAccent,
                      width: 14),
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

  void _agregarEncuentro(Encuentro nuevo) {
    setState(() {
      encuentros.add(nuevo);
    });
  }

  int _calcularStreak() {
    if (encuentros.isEmpty) return 0;

    final fechas = encuentros.map((e) => DateUtils.dateOnly(e.fecha)).toSet();
    final hoy = DateUtils.dateOnly(DateTime.now());
    int streak = 0;

    for (int i = 0;; i++) {
      final dia = hoy.subtract(Duration(days: i));
      if (fechas.contains(dia)) {
        streak++;
      } else {
        if (i == 0) continue; // hoy no cuenta
        if (i == 1 && streak == 0) return -1; // ayer no hubo y antes sí
        break;
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
                      DropdownMenuItem(
                          value: 'Satisfacción', child: Text('Satisfacción')),
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
      appBar: AppBar(title: Text('Nuevo encuentro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title:
                    Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_fecha)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _seleccionarFecha(context),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Lugar'),
                onChanged: (val) => _lugar = val,
              ),
              DropdownButtonFormField<String>(
                value: _tipo,
                items: ['Penetración', 'Oral', 'Beso', 'Otro']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => _tipo = val!,
                decoration: InputDecoration(labelText: 'Tipo'),
              ),
              SizedBox(height: 16),
              Text('Duración (min): $_duracionMin'),
              Slider(
                value: _duracionMin.toDouble(),
                min: 1,
                max: 120,
                divisions: 24,
                label: '$_duracionMin min',
                onChanged: (val) => setState(() => _duracionMin = val.toInt()),
              ),
              SizedBox(height: 16),
              Text('Satisfacción: $_satisfaccion'),
              Slider(
                value: _satisfaccion.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_satisfaccion',
                onChanged: (val) => setState(() => _satisfaccion = val.toInt()),
              ),
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
