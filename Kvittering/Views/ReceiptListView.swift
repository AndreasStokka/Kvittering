import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ReceiptListViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Alle filtre i én seksjon for minimal spacing
                Section {
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
                                        // Valider doubleValue før return
                                        if doubleValue.isNaN || doubleValue.isInfinite {
                                            return 0.0
                                        }
                                        return doubleValue
                                    },
                                    set: { 
                                        let newValue = Decimal($0)
                                        // Valider før tildeling
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
                                        // Valider doubleValue før return
                                        if doubleValue.isNaN || doubleValue.isInfinite {
                                            return 50000.0
                                        }
                                        return doubleValue
                                    },
                                    set: { 
                                        let newValue = Decimal($0)
                                        // Valider før tildeling
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

                Section {
                    if viewModel.receipts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary.opacity(0.5))
                            Text("Ingen kvitteringer funnet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        ForEach(viewModel.receipts, id: \.id) { receipt in
                            NavigationLink(value: receipt) {
                                HStack(spacing: 12) {
                                    Image(systemName: CategoryIconHelper.icon(for: receipt.category))
                                        .font(.system(size: 16))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 32, height: 32)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(receipt.storeName)
                                            .font(.title3.bold())
                                            .foregroundStyle(.primary)
                                        
                                        Text(formatDate(receipt.purchaseDate))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        let category = Category.migrate(receipt.category)
                                        Text(category.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatAmount(receipt.totalAmount))
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowSeparator(.visible)
                        }
                    }
                } header: {
                    Text("Mine kvitteringer (\(viewModel.receipts.count))")
                }
            }
            .listStyle(.insetGrouped)
            .navigationDestination(for: Receipt.self) { receipt in
                ReceiptDetailView(receipt: receipt)
            }
            .navigationTitle("Mine kvitteringer")
            .onAppear {
                viewModel.attach(context: modelContext)
            }
        }
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        return AmountFormatter.format(amount)
    }
    
    private func formatDate(_ date: Date) -> String {
        return ReceiptDateFormatter.format(date)
    }
}
