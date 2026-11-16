module ApplicationHelper
    def money(amount)
        "#{number_with_precision(amount, precision: 2, delimiter: ' ', separator: ',')} ₽"
    end
end
