export interface ReceiptPayload {
  payment_id: string;
  receipt_number: string;
  student_id: string;
  amount: number;
  currency: string;

  /**
   * Obligatoire pour Flutterwave.
   * Absent ou null pour un paiement en espèces.
   */
  flutterwave_transaction_id?: string | null;

  paid_at: string;
}