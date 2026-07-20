import Foundation
import SwiftData

struct BudgetSummary {
    let totalBudget: Decimal
    let coveredExpense: Decimal
    let uncoveredExpense: Decimal
    let remaining: Decimal
    let safeDaily: Decimal
    let activeBudgetCount: Int

    var progress: Double {
        guard totalBudget > 0 else { return 0 }
        return Double(truncating: (coveredExpense / totalBudget) as NSNumber)
    }
}

struct BudgetDetail {
    let budgetID: UUID
    let amount: Decimal
    let used: Decimal
    let remaining: Decimal
    let safeDaily: Decimal
}

protocol BudgetCalculating {
    func summary(ledgerID: UUID, at date: Date) throws -> BudgetSummary
    func detail(budgetID: UUID, at date: Date) throws -> BudgetDetail
}

enum BudgetCalculationError: LocalizedError {
    case budgetNotFound

    var errorDescription: String? { "未找到预算" }
}

@MainActor
final class BudgetCalculator: BudgetCalculating {
    private let modelContext: ModelContext
    private let calendar: Calendar

    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    func summary(ledgerID: UUID, at date: Date) throws -> BudgetSummary {
        let allBudgets = try modelContext.fetch(FetchDescriptor<Budget>())
        let budgets = allBudgets.filter {
            $0.ledger?.id == ledgerID && $0.startDate <= date && date < $0.endDate
        }
        let allTransactions = try modelContext.fetch(FetchDescriptor<Transaction>())
        let expenses = allTransactions.filter {
            $0.ledger?.id == ledgerID && $0.type == .expense
        }

        let totalBudget = budgets.reduce(Decimal(0)) {
            $0 + $1.amount + $1.rolloverAmount
        }
        var coveredTransactionIDs = Set<UUID>()
        var safeDaily = Decimal(0)

        for budget in budgets {
            let categoryIDs = categoryIDsCovered(by: budget)
            let used = expenses
                .filter {
                    budget.startDate <= $0.date && $0.date < budget.endDate &&
                    $0.category.map { categoryIDs.contains($0.id) } == true
                }
            used.forEach { coveredTransactionIDs.insert($0.id) }
            let usedAmount = used.reduce(Decimal(0)) { $0 + $1.amount }
            let remaining = budget.amount + budget.rolloverAmount - usedAmount
            let remainingDays = max(
                calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: date),
                    to: budget.endDate
                ).day ?? 1,
                1
            )
            safeDaily += max(remaining, 0) / Decimal(remainingDays)
        }

        let coveredExpense = expenses
            .filter { coveredTransactionIDs.contains($0.id) }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let totalExpense = expenses
            .filter { transaction in
                budgets.contains {
                    $0.startDate <= transaction.date && transaction.date < $0.endDate
                }
            }
            .reduce(Decimal(0)) { $0 + $1.amount }

        return BudgetSummary(
            totalBudget: totalBudget,
            coveredExpense: coveredExpense,
            uncoveredExpense: max(totalExpense - coveredExpense, 0),
            remaining: totalBudget - coveredExpense,
            safeDaily: safeDaily,
            activeBudgetCount: budgets.count
        )
    }

    func detail(budgetID: UUID, at date: Date) throws -> BudgetDetail {
        let descriptor = FetchDescriptor<Budget>(predicate: #Predicate { $0.id == budgetID })
        guard let budget = try modelContext.fetch(descriptor).first else {
            throw BudgetCalculationError.budgetNotFound
        }
        let categoryIDs = categoryIDsCovered(by: budget)
        let transactions = try modelContext.fetch(FetchDescriptor<Transaction>())
        let used = transactions
            .filter {
                $0.ledger?.id == budget.ledger?.id &&
                $0.type == .expense &&
                budget.startDate <= $0.date && $0.date < budget.endDate &&
                $0.category.map { categoryIDs.contains($0.id) } == true
            }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let remaining = budget.amount + budget.rolloverAmount - used
        let remainingDays = max(
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: date),
                to: budget.endDate
            ).day ?? 1,
            1
        )
        return BudgetDetail(
            budgetID: budgetID,
            amount: budget.amount + budget.rolloverAmount,
            used: used,
            remaining: remaining,
            safeDaily: max(remaining, 0) / Decimal(remainingDays)
        )
    }

    private func categoryIDsCovered(by budget: Budget) -> Set<UUID> {
        guard let category = budget.category else { return [] }
        var ids: Set<UUID> = [category.id]
        var queue = category.children ?? []
        while let child = queue.popLast() {
            ids.insert(child.id)
            queue.append(contentsOf: child.children ?? [])
        }
        return ids
    }
}
