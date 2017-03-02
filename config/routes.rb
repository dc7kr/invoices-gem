CorikaInvoices::Engine.routes.draw do

    resources :invoice_customers
    resources :invoice_items
    resources :invoices do 
      member do 
        get :gen_pdf
        get :gen_sepa
      end
    end
end
