//
//  TimeSliderView.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-11.
//

import SwiftUI

struct TimeSliderView: View {
	@State private var circlePosition = CGSize(width: 0, height: 0)
	@State private var timePosition = CGSize(width: 0, height: 0)
	@GestureState private var isDragging = false
	
	@ObservedObject var model: LocationModel
	let data: [UV]
	
    var body: some View {
		GeometryReader { geometry in
			HStack {
				Spacer()
				
				VStack(alignment: .trailing) {
					Text(model.date.formatted(formatStyle.weekday(.wide)))
						.font(.footnote)
					
					Text(model.date.formatted(formatStyle.hour().minute()))
				}
				.padding(.horizontal, horizontalPadding)
				.padding(.vertical, 5)
				.lineLimit(1)
				.background(Color.tertiarySystemBackground)
				.cornerRadius(10)
				.offset(timePosition)
				.isHidden(isDragging == false || self.data.isEmpty)
				.accessibilityHidden(true)
				
				ZStack {
					RoundedRectangle(cornerRadius: 20)
						.fill(Color.tertiarySystemBackground)
						.frame(width: 5)
					
					Circle()
						.fill(Color.accentColor)
						.frame(width: 25)
						.shadow(color: .gray, radius: 10, x: 0, y: 2)
						.offset(circlePosition)
						.gesture(DragGesture().onChanged({ value in
							handleGesture(value: value, height: geometry.size.height)
						}).updating($isDragging, body: { (_, state, _) in
							state = true
						}).onEnded({ value in
							let feedback = UIImpactFeedbackGenerator(style: .rigid)
							feedback.impactOccurred()
						}))
						.onAppear(perform: {
							let height = geometry.size.height
							let sliderHeight = height - 2*outerPadding
							
							circlePosition = CGSize(width: 0, height: -sliderHeight/2)
						})
						.onChange(of: model.resetSliderDate) { _ in
							resetSlider(height: geometry.size.height)
						}
				}
//				.accessibilityRepresentation {
//					DatePicker("Pick a date and time to view future levels",
//							   selection: $model.date,
//							   in: accessibilityRange,
//							   displayedComponents: [.date, .hourAndMinute])
//				}
				
				RoundedRectangle(cornerRadius: 5)
					.fill(LinearGradient(gradient: Gradient(colors: gradientColors),
										 startPoint: .top,
										 endPoint: .bottom))
					.frame(width: 30)
					.mask(VStack(spacing: 1) {
						// Today
						RoundedRectangle(cornerRadius: 5)
							.frame(height: scaleUntilMidnight * geometry.size.height)
							.isHidden(scaleUntilMidnight < 0.007, remove: true) // (20min)/(2days/60=2880)
						
						// Tomorrow
						RoundedRectangle(cornerRadius: 5)
							.frame(height: 0.5 * geometry.size.height - 2*outerPadding)
						
						// Day after tomorrow
						RoundedRectangle(cornerRadius: 5)
					})
					.accessibilityHidden(true)
			}
			.padding(.vertical, outerPadding)
		}
		.accessibilityElement()
		.accessibilityLabel("Chart representing upcoming 48 hours of UV Index data")
		.accessibilityChartDescriptor(self)
    }
	
	private let outerPadding: CGFloat = 0
	private let horizontalPadding: CGFloat = 7
	private let defaultRange: TimeInterval = 2*24*3600
	
	private var gradientColors: [Color] {
		self.data.map { $0.color }
	}
	
	private var timeZone: TimeZone {
		model.location?.timeZone ?? .current
	}
	
	private var accessibilityRange: ClosedRange<Date> {
		Date()...Date().addingTimeInterval(defaultRange)
	}
	
	// Scale representing the height of the top-most rectangle
	private var scaleUntilMidnight: CGFloat {
		guard !self.data.isEmpty else {
			return 0
		}
		
		let now = model.now
		
		let interval = defaultRange
		let endOfDay = now.endOfDay(timezone: self.timeZone) - now
		
		return CGFloat(endOfDay / interval)
	}
	
	// Scale representing the height of the last rectangle
	private var scaleTomorrow: CGFloat {
		guard !data.isEmpty else {
			return 0
		}
		
		let now = model.now
		
		let interval = defaultRange
		let todayInterval = now.endOfDay(timezone: self.timeZone) - now
		let reducedDay = interval - todayInterval - 24*3600
		
		return CGFloat(reducedDay / interval)
	}
	
	private var calendar: Calendar {
		var calendar = Calendar.current
		calendar.locale = .current
		calendar.timeZone = self.timeZone
		return calendar
	}
	
	private var formatStyle: Date.FormatStyle {
		Date.FormatStyle(calendar: self.calendar, timeZone: self.timeZone)
	}
	
	private var sliderY: CGFloat {
		circlePosition.height
	}
	
	private func resetSlider(height: Double) {
		let sliderHeight = height - 2*outerPadding
		let y: CGFloat = -sliderHeight/2
		
		self.circlePosition = CGSize(width: 0, height: y)
		self.timePosition = CGSize(width: 0, height: y)
	}
	
	private func handleGesture(value: DragGesture.Value, height: Double) {
		guard !self.data.isEmpty else {
			return
		}
		
		let now = model.now
		let dragY = value.location.y
		let sliderHeight = height - 2*outerPadding
		var y: CGFloat = -sliderHeight/2
		
		// Limit slider from leaving the slider
		if dragY < 0 {
			y = -sliderHeight/2
		} else if dragY > sliderHeight {
			y = sliderHeight/2
		} else {
			y = dragY-sliderHeight/2
		}
		
		// Update slider position
		self.circlePosition = CGSize(width: 0, height: y)
		self.timePosition = CGSize(width: 0, height: y)
		
		// Calculate date from slider position
		let date = now.addingTimeInterval(defaultRange * (0.5 + Double(y/sliderHeight)))
		
		// Find difference between new and old hour
		let previousHour = calendar.component(.hour, from: model.date)
		let newHour = calendar.component(.hour, from: date)
		
		// Update the model
		model.date = date
		
		// Make haptic feedback at every new hour
		if newHour != previousHour {
			let feedback = UISelectionFeedbackGenerator()
			feedback.selectionChanged()
		}
	}
}

#if DEBUG
struct TimeSliderView_Previews: PreviewProvider {
	static var previews: some View {
		let stockholm = Location(title: "Stockholm", subtitle: "Sweden",
								 coordinates: Coordinate(latitude: 59.3279943,
														 longitude: 18.054674),
								 timeZone: .current)
		
		StateView(location: stockholm)
    }
	
	struct StateView: View {
		@State var date = Date()
		@StateObject private var model: LocationModel
		
		let location: Location
		
		init(location: Location) {
			self.location = location
			
			_model = StateObject(wrappedValue: LocationModel(location, isUserLocation: false))
		}
		
		var body: some View {
			TimeSliderView(model: model, data: UV.testData)
				.frame(width: 200, height: 400)
				.previewLayout(.sizeThatFits)
				.padding()
				.background(Color.systemBackground)
		}
	}
}
#endif

extension TimeSliderView: AXChartDescriptorRepresentable {
	func makeChartDescriptor() -> AXChartDescriptor {
		let xAxis = AXCategoricalDataAxisDescriptor(
			title: "Time",
			categoryOrder: data.map({ $0.date.formatted(date: .long, time: .shortened) })
		)
		
		let min = data.map({ Double($0.index) }).min() ?? 0.0
		let max = data.map({ Double($0.index) }).max() ?? 0.0
		
		let yAxis = AXNumericDataAxisDescriptor(
			title: "UV Index",
			range: min...max,
			gridlinePositions: []
		) { value in "UV Index \(value)" }
		
		let series = AXDataSeriesDescriptor(
			name: "",
			isContinuous: false,
			dataPoints: data.map {
				.init(x: $0.date.formatted(date: .long, time: .shortened),
					  y: Double($0.index))
			}
		)
		
		return AXChartDescriptor(
			title: "Chart representing upcoming 48 hours of UV Index data",
			summary: nil,
			xAxis: xAxis,
			yAxis: yAxis,
			additionalAxes: [],
			series: [series]
		)
	}
}
