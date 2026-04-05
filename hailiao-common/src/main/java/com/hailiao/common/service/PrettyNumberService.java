package com.hailiao.common.service;

import com.hailiao.common.entity.PrettyNumber;
import com.hailiao.common.repository.PrettyNumberRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.criteria.Predicate;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Service
public class PrettyNumberService {

    @Autowired
    private PrettyNumberRepository prettyNumberRepository;

    @Transactional
    public PrettyNumber createPrettyNumber(String number, Integer level, BigDecimal price) {
        if (prettyNumberRepository.findByNumber(number).isPresent()) {
            throw new RuntimeException("靓号已存在");
        }

        PrettyNumber prettyNumber = new PrettyNumber();
        prettyNumber.setNumber(number);
        prettyNumber.setLevel(level);
        prettyNumber.setPrice(price);
        prettyNumber.setStatus(0);
        prettyNumber.setCreatedAt(new Date());

        return prettyNumberRepository.save(prettyNumber);
    }

    public PrettyNumber getPrettyNumberById(Long id) {
        return prettyNumberRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("靓号不存在"));
    }

    public PrettyNumber getPrettyNumberByNumber(String number) {
        return prettyNumberRepository.findByNumber(number)
                .orElseThrow(() -> new RuntimeException("靓号不存在"));
    }

    public Page<PrettyNumber> getPrettyNumberList(Integer status, Integer level, Long userId, Pageable pageable) {
        Specification<PrettyNumber> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            if (level != null) {
                predicates.add(cb.equal(root.get("level"), level));
            }

            if (userId != null) {
                predicates.add(cb.equal(root.get("userId"), userId));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return prettyNumberRepository.findAll(spec, pageable);
    }

    public List<PrettyNumber> getAvailablePrettyNumbers() {
        return prettyNumberRepository.findByStatus(0);
    }

    @Transactional
    public PrettyNumber buyPrettyNumber(Long prettyNumberId, Long userId) {
        PrettyNumber prettyNumber = getPrettyNumberById(prettyNumberId);

        if (prettyNumber.getStatus() == 1) {
            throw new RuntimeException("靓号已被购买");
        }

        prettyNumber.setStatus(1);
        prettyNumber.setUserId(userId);
        prettyNumber.setBuyTime(new Date());

        return prettyNumberRepository.save(prettyNumber);
    }

    @Transactional
    public void releasePrettyNumber(Long prettyNumberId) {
        PrettyNumber prettyNumber = getPrettyNumberById(prettyNumberId);
        prettyNumber.setStatus(0);
        prettyNumber.setUserId(null);
        prettyNumber.setBuyTime(null);
        prettyNumberRepository.save(prettyNumber);
    }

    @Transactional
    public PrettyNumber updatePrettyNumberPrice(Long prettyNumberId, BigDecimal price) {
        PrettyNumber prettyNumber = getPrettyNumberById(prettyNumberId);
        prettyNumber.setPrice(price);
        return prettyNumberRepository.save(prettyNumber);
    }

    public long getTotalPrettyNumberCount() {
        return prettyNumberRepository.count();
    }

    public long getAvailablePrettyNumberCount() {
        return prettyNumberRepository.countByStatus(0);
    }

    public long getSoldPrettyNumberCount() {
        return prettyNumberRepository.countByStatus(1);
    }
}
