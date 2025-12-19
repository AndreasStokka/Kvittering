import SwiftUI

/// View for å vise alle filtre for kvitteringslisten
struct ReceiptListFiltersView: View {
    @ObservedObject var viewModel: ReceiptListViewModel
    
    var body: some View {
        Section {
            SearchFilterView(viewModel: viewModel)
            CategoryFilterView(viewModel: viewModel)
            DateFilterView(viewModel: viewModel)
            AmountFilterView(viewModel: viewModel)
        }
    }
}

/// View for søkefilter
private struct SearchFilterView: View {
    @ObservedObject var viewModel: ReceiptListViewModel
    
    var body: some View {
        DisclosureGroup("Søk", isExpanded: $viewModel.showSearchFilter) {
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Søk", text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { _, _ in viewModel.load() }
                }
                
                Picker("Søk i", selection: $viewModel.searchScope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .onChange(of: viewModel.searchScope) { _, _ in viewModel.load() }
            }
            .padding(.top, 2)
        }
    }
}

/// View for kategorifilter
private struct CategoryFilterView: View {
    @ObservedObject var viewModel: ReceiptListViewModel
    
    var body: some View {
        DisclosureGroup("Kategori", isExpanded: $viewModel.showCategoryFilter) {
            Picker("Kategori", selection: Binding(
                get: { viewModel.selectedCategory },
                set: { viewModel.selectedCategory = $0; viewModel.load() }
            )) {
                Text("Alle kategorier").tag(Category?.none)
                ForEach(Category.allCases) { category in
                    HStack {
                        Image(systemName: CategoryIconHelper.icon(for: category))
                        Text(category.rawValue)
                    }
                    .tag(Category?.some(category))
                }
            }
            .padding(.top, 2)
        }
    }
}

/// View for datofilter
private struct DateFilterView: View {
    @ObservedObject var viewModel: ReceiptListViewModel
    
    var body: some View {
        DisclosureGroup("Datofilter", isExpanded: $viewModel.showDateFilter) {
            VStack(alignment: .leading, spacing: 6) {
                DatePicker("Fra dato", selection: $viewModel.fromDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                DatePicker("Til dato", selection: $viewModel.toDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                Button {
                    viewModel.updateDateRange()
                } label: {
                    HStack {
                        Spacer()
                        Text("Bruk filter")
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.85))
                    .foregroundStyle(.white)
                    .cornerRadius(6)
                }
            }
            .padding(.top, 2)
        }
        .onChange(of: viewModel.showDateFilter) { _, isOn in
            if !isOn {
                viewModel.dateRange = nil
                viewModel.load()
            }
        }
    }
}

/// View for beløpsfilter
private struct AmountFilterView: View {
    @ObservedObject var viewModel: ReceiptListViewModel
    
    private func formatAmount(_ amount: Decimal) -> String {
        return AmountFormatter.format(amount)
    }
    
    var body: some View {
        DisclosureGroup("Beløpsfilter", isExpanded: $viewModel.showAmountFilter) {
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Min: \(formatAmount(viewModel.minAmount))")
                        .font(.caption.weight(.medium))
                    Slider(value: Binding(
                        get: {
                            let amount = viewModel.minAmount
                            if amount.isNaN || amount.isInfinite {
                                return 0.0
                            }
                            let nsDecimal = NSDecimalNumber(decimal: amount)
                            let doubleValue = nsDecimal.doubleValue
                            if doubleValue.isNaN || doubleValue.isInfinite {
                                return 0.0
                            }
                            return doubleValue
                        },
                        set: { 
                            let newValue = Decimal($0)
                            if !newValue.isNaN && !newValue.isInfinite {
                                viewModel.minAmount = newValue
                            }
                        }
                    ), in: 0...50000, step: 100)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Maks: \(formatAmount(viewModel.maxAmount))")
                        .font(.caption.weight(.medium))
                    Slider(value: Binding(
                        get: {
                            let amount = viewModel.maxAmount
                            if amount.isNaN || amount.isInfinite {
                                return 50000.0
                            }
                            let nsDecimal = NSDecimalNumber(decimal: amount)
                            let doubleValue = nsDecimal.doubleValue
                            if doubleValue.isNaN || doubleValue.isInfinite {
                                return 50000.0
                            }
                            return doubleValue
                        },
                        set: { 
                            let newValue = Decimal($0)
                            if !newValue.isNaN && !newValue.isInfinite {
                                viewModel.maxAmount = newValue
                            }
                        }
                    ), in: 0...50000, step: 100)
                }
                
                Button {
                    viewModel.updateAmountRange()
                } label: {
                    HStack {
                        Spacer()
                        Text("Bruk filter")
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.85))
                    .foregroundStyle(.white)
                    .cornerRadius(6)
                }
            }
            .padding(.top, 2)
        }
        .onChange(of: viewModel.showAmountFilter) { _, isOn in
            if !isOn {
                viewModel.amountRange = nil
                viewModel.load()
            }
        }
    }
}



