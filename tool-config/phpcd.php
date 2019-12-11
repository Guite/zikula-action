<?php

$builder = new \Akeneo\CouplingDetector\RuleBuilder();

$rules = [
    $builder->forbids(['bar', 'baz'])->in('foo'),
    $builder->discourages(['too'])->in('zoo'),
    $builder->only(['bla', 'ble', 'blu'])->in('bli'),
];

return new \Akeneo\CouplingDetector\Configuration\Configuration(
    $rules,
    new \Akeneo\CouplingDetector\Configuration\DefaultFinder()
);
