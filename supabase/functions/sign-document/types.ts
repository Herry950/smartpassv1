export interface ReceiptPayload {
  payment_id: string;

  receipt_number: string;

  student_id: string;

  amount: number;

  currency: string;

  transaction_id: string;

  paid_at: string;
}