# frozen_string_literal: true

# ransack 4 searched cont/start/end (and their not_ forms) with ILIKE on
# PostgreSQL; 6.x made them case-sensitive and added i_cont & co. for the old
# behaviour. Every ActiveAdmin text filter uses the plain ones, so in QA and
# production a search for "arg" stopped finding "Argentina" (#241). Same
# predicates, ransack's own definitions (formatter and wildcard escaping
# included), with case ignored again. ActiveAdmin is heading the same way
# (activeadmin#9134, string filters on i_cont).
CASE_INSENSITIVE_PREDICATES = %w[cont not_cont start not_start end not_end].freeze

Ransack.configure do |config|
  Ransack::Constants::DERIVED_PREDICATES.each do |name, options|
    next unless CASE_INSENSITIVE_PREDICATES.include?(name)

    config.add_predicate(name, options.merge(case_insensitive: true))
  end
end
