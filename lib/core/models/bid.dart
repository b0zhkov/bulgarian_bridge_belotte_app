import 'contract.dart';

enum BidKind { pass, contract, double, redouble }

class Bid {
  const Bid._(this.kind, [this.type]);

  static const pass = Bid._(BidKind.pass);
  static const double = Bid._(BidKind.double);
  static const redouble = Bid._(BidKind.redouble);
  const Bid.contract(ContractType t) : this._(BidKind.contract, t);

  final BidKind kind;
  final ContractType? type;

  @override
  bool operator ==(Object other) =>
      other is Bid && other.kind == kind && other.type == type;

  @override
  int get hashCode => Object.hash(kind, type);

  @override
  String toString() => kind == BidKind.contract ? 'Bid(${type!.name})' : 'Bid(${kind.name})';
}

class SeatBid {
  const SeatBid(this.seat, this.bid);
  final int seat;
  final Bid bid;
  @override
  String toString() => '$seat:$bid';
}
