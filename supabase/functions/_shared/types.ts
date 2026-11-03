export interface Student {
  id: string;
  auth_user_id: string;
  matricule: string;
  full_name: string;
  email: string;
}

export interface ExamSession {
  id: string;
  session_name: string;
  semester: string;
  fee_amount: number;
  currency: string;
  payment_open: boolean;
  academic_year_id: string;
}

export interface Payment {
  id: string;
  student_id: string;
  exam_session_id: string;
  amount: number;
  currency: string;
  payment_method: string;
  payment_channel: string;
  provider: string | null;
  flutterwave_transaction_id: string | null;
  flutterwave_tx_ref: string | null;
  status: string;
  validated_by: string | null;
  cash_remitted: boolean;
  remitted_at: string | null;
  receipt_url: string | null;
  paid_at: string | null;
  created_at: string;
  receipt_number: string | null;
  receipt_signature: string | null;
}

export interface FlutterwaveCheckoutResponse {
  status: string;
  message: string;
  data: {
    link: string;
  };
}