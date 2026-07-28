export function generateTxRef(
  matricule: string,
) {
  return `SMARTPASS-${matricule}-${Date.now()}`;
}